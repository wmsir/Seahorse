use serde::{Deserialize, Serialize};
use std::fs;
use std::io::{Read, Write};
use std::net::{TcpStream, ToSocketAddrs};
use std::path::PathBuf;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use tauri::menu::{Menu, MenuItem, PredefinedMenuItem};
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent};
use tauri::{AppHandle, Manager, Runtime, Window};

pub const DEFAULT_API_BASE_URL: &str = "https://fwpt.cn/api";
const LEGACY_API_BASE_URL: &str = "https://fwpt.cn/seahorse/api";
const CONFIG_DIR_NAME: &str = "seahorse_desktop";
const CONFIG_FILE_NAME: &str = "config.json";

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct DesktopConfig {
    #[serde(alias = "api_base_url")]
    pub api_base_url: String,
    #[serde(default)]
    pub config_path: String,
    #[serde(default)]
    pub updated_at: u64,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct DesktopConfigInput {
    #[serde(alias = "api_base_url")]
    pub api_base_url: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct DesktopRuntimeInfo {
    pub product_name: String,
    pub app_title: String,
    pub version: String,
    pub identifier: String,
    pub os: String,
    pub arch: String,
    pub family: String,
    pub config_dir: String,
    pub config_path: String,
    pub exe_path: String,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ProbeResult {
    pub reachable: bool,
    pub status_code: Option<u16>,
    pub latency_ms: u64,
    pub target: String,
    pub message: String,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct StoredConfigFile {
    #[serde(alias = "api_base_url")]
    api_base_url: String,
    #[serde(default)]
    updated_at: u64,
}

fn now_epoch_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

fn config_dir_path() -> PathBuf {
    dirs::config_dir()
        .or_else(dirs::data_local_dir)
        .or_else(|| dirs::home_dir().map(|h| h.join(".config")))
        .unwrap_or_else(std::env::temp_dir)
        .join(CONFIG_DIR_NAME)
}

fn config_file_path() -> PathBuf {
    config_dir_path().join(CONFIG_FILE_NAME)
}

pub fn normalize_api_base_url(raw: &str) -> Result<String, String> {
    let trimmed = raw.trim().trim_end_matches('/');
    if trimmed.is_empty() {
        return Err("服务端 API 地址不能为空".to_string());
    }
    let lower = trimmed.to_ascii_lowercase();
    if !(lower.starts_with("http://") || lower.starts_with("https://")) {
        return Err("服务端 API 地址必须以 http:// 或 https:// 开头".to_string());
    }
    if trimmed.eq_ignore_ascii_case(LEGACY_API_BASE_URL) {
        return Ok(DEFAULT_API_BASE_URL.to_string());
    }
    Ok(trimmed.to_string())
}

fn load_or_init_config() -> Result<DesktopConfig, String> {
    let dir = config_dir_path();
    let file = config_file_path();
    let path_str = file.to_string_lossy().to_string();

    if file.exists() {
        if let Ok(raw) = fs::read_to_string(&file) {
            if let Ok(stored) = serde_json::from_str::<StoredConfigFile>(&raw) {
                if let Ok(clean_url) = normalize_api_base_url(&stored.api_base_url) {
                    if stored
                        .api_base_url
                        .trim()
                        .trim_end_matches('/')
                        .eq_ignore_ascii_case(LEGACY_API_BASE_URL)
                    {
                        let ts = now_epoch_ms();
                        let migrated = StoredConfigFile {
                            api_base_url: clean_url.clone(),
                            updated_at: ts,
                        };
                        if let Ok(serialized) = serde_json::to_string_pretty(&migrated) {
                            let _ = fs::write(&file, serialized);
                        }
                        return Ok(DesktopConfig {
                            api_base_url: clean_url,
                            config_path: path_str,
                            updated_at: ts,
                        });
                    }
                    return Ok(DesktopConfig {
                        api_base_url: clean_url,
                        config_path: path_str,
                        updated_at: stored.updated_at,
                    });
                }
            }
        }
    }

    let _ = fs::create_dir_all(&dir);
    let ts = now_epoch_ms();
    let initial = StoredConfigFile {
        api_base_url: DEFAULT_API_BASE_URL.to_string(),
        updated_at: ts,
    };
    if let Ok(serialized) = serde_json::to_string_pretty(&initial) {
        let _ = fs::write(&file, serialized);
    }

    Ok(DesktopConfig {
        api_base_url: DEFAULT_API_BASE_URL.to_string(),
        config_path: path_str,
        updated_at: ts,
    })
}

fn persist_config(raw_url: &str) -> Result<DesktopConfig, String> {
    let clean_url = normalize_api_base_url(raw_url)?;
    let dir = config_dir_path();
    fs::create_dir_all(&dir).map_err(|e| format!("无法创建配置目录 ({}): {}", dir.display(), e))?;

    let file = config_file_path();
    let ts = now_epoch_ms();
    let stored = StoredConfigFile {
        api_base_url: clean_url.clone(),
        updated_at: ts,
    };
    let serialized = serde_json::to_string_pretty(&stored)
        .map_err(|e| format!("序列化桌面端配置失败: {}", e))?;
    fs::write(&file, serialized)
        .map_err(|e| format!("写入桌面端配置文件失败 ({}): {}", file.display(), e))?;

    Ok(DesktopConfig {
        api_base_url: clean_url,
        config_path: file.to_string_lossy().to_string(),
        updated_at: ts,
    })
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParsedEndpoint {
    pub scheme: String,
    pub host: String,
    pub port: u16,
    pub base_path: String,
}

pub fn parse_endpoint(raw_url: &str) -> Result<ParsedEndpoint, String> {
    let normalized = normalize_api_base_url(raw_url)?;
    let (scheme, rest) = if let Some(r) = normalized.strip_prefix("https://") {
        ("https".to_string(), r)
    } else if let Some(r) = normalized.strip_prefix("http://") {
        ("http".to_string(), r)
    } else {
        let lower = normalized.to_ascii_lowercase();
        if lower.starts_with("https://") {
            ("https".to_string(), &normalized[8..])
        } else if lower.starts_with("http://") {
            ("http".to_string(), &normalized[7..])
        } else {
            return Err("不支持的协议前缀".to_string());
        }
    };

    let (authority, path_part) = match rest.find('/') {
        Some(idx) => (&rest[..idx], &rest[idx..]),
        None => (rest, ""),
    };

    let default_port = if scheme == "https" { 443 } else { 80 };
    let (host, port) = if authority.starts_with('[') {
        // IPv6 literal, e.g. [::1]:8082
        let end_bracket = authority
            .find(']')
            .ok_or_else(|| "无效的 IPv6 主机地址".to_string())?;
        let h = &authority[1..end_bracket];
        let after = &authority[end_bracket + 1..];
        let p = if let Some(port_str) = after.strip_prefix(':') {
            port_str
                .parse::<u16>()
                .map_err(|_| format!("无效端口号: {}", port_str))?
        } else {
            default_port
        };
        (h.to_string(), p)
    } else if let Some((h, p_str)) = authority.rsplit_once(':') {
        let p = p_str
            .parse::<u16>()
            .map_err(|_| format!("无效端口号: {}", p_str))?;
        (h.to_string(), p)
    } else {
        (authority.to_string(), default_port)
    };

    if host.trim().is_empty() {
        return Err("服务端主机名不能为空".to_string());
    }

    Ok(ParsedEndpoint {
        scheme,
        host,
        port,
        base_path: path_part.trim_end_matches('/').to_string(),
    })
}

fn probe_endpoint_blocking(target_url: &str, timeout_ms: u64) -> ProbeResult {
    let parsed = match parse_endpoint(target_url) {
        Ok(p) => p,
        Err(err) => {
            return ProbeResult {
                reachable: false,
                status_code: None,
                latency_ms: 0,
                target: target_url.to_string(),
                message: err,
            };
        }
    };

    let timeout = Duration::from_millis(timeout_ms.clamp(500, 15_000));
    let start = Instant::now();

    let addrs: Vec<_> = match (parsed.host.as_str(), parsed.port).to_socket_addrs() {
        Ok(iter) => iter.collect(),
        Err(e) => {
            return ProbeResult {
                reachable: false,
                status_code: None,
                latency_ms: start.elapsed().as_millis() as u64,
                target: target_url.to_string(),
                message: format!("DNS 解析失败 ({}:{}): {}", parsed.host, parsed.port, e),
            };
        }
    };

    if addrs.is_empty() {
        return ProbeResult {
            reachable: false,
            status_code: None,
            latency_ms: start.elapsed().as_millis() as u64,
            target: target_url.to_string(),
            message: format!("未解析到有效主机地址 ({}:{})", parsed.host, parsed.port),
        };
    }

    let mut last_err = String::new();
    let mut connected_stream: Option<TcpStream> = None;
    for addr in addrs {
        match TcpStream::connect_timeout(&addr, timeout) {
            Ok(s) => {
                connected_stream = Some(s);
                break;
            }
            Err(e) => {
                last_err = e.to_string();
            }
        }
    }

    let mut stream = match connected_stream {
        Some(s) => s,
        None => {
            return ProbeResult {
                reachable: false,
                status_code: None,
                latency_ms: start.elapsed().as_millis() as u64,
                target: target_url.to_string(),
                message: format!(
                    "TCP 连接不可达 ({}:{}): {}",
                    parsed.host, parsed.port, last_err
                ),
            };
        }
    };

    if parsed.scheme == "https" {
        let latency_ms = start.elapsed().as_millis() as u64;
        return ProbeResult {
            reachable: true,
            status_code: None,
            latency_ms,
            target: target_url.to_string(),
            message: format!(
                "HTTPS 网关端口连通正常 ({}:{}, {}ms)",
                parsed.host, parsed.port, latency_ms
            ),
        };
    }

    let _ = stream.set_write_timeout(Some(timeout));
    let _ = stream.set_read_timeout(Some(timeout));

    let ping_path = if parsed.base_path.is_empty() {
        "/api/ping".to_string()
    } else {
        format!("{}/ping", parsed.base_path)
    };
    let host_hdr = if parsed.port == 80 {
        parsed.host.clone()
    } else {
        format!("{}:{}", parsed.host, parsed.port)
    };
    let req = format!(
        "GET {} HTTP/1.1\r\nHost: {}\r\nUser-Agent: SeahorseDesktop/{}\r\nAccept: application/json,*/*\r\nConnection: close\r\n\r\n",
        ping_path,
        host_hdr,
        env!("CARGO_PKG_VERSION")
    );

    if let Err(e) = stream.write_all(req.as_bytes()) {
        return ProbeResult {
            reachable: false,
            status_code: None,
            latency_ms: start.elapsed().as_millis() as u64,
            target: target_url.to_string(),
            message: format!("发送 HTTP 探测请求失败: {}", e),
        };
    }

    let mut buf = [0u8; 512];
    match stream.read(&mut buf) {
        Ok(n) if n > 0 => {
            let latency_ms = start.elapsed().as_millis() as u64;
            let head = String::from_utf8_lossy(&buf[..n]);
            let first_line = head.lines().next().unwrap_or("");
            let status_code = first_line
                .split_whitespace()
                .nth(1)
                .and_then(|s| s.parse::<u16>().ok());
            let ok = status_code.map(|c| c < 500).unwrap_or(true);
            ProbeResult {
                reachable: ok,
                status_code,
                latency_ms,
                target: target_url.to_string(),
                message: match status_code {
                    Some(code) => format!("HTTP 响应 {} ({}ms)", code, latency_ms),
                    None => format!("TCP/HTTP 已连通 ({}ms)", latency_ms),
                },
            }
        }
        Ok(_) => {
            let latency_ms = start.elapsed().as_millis() as u64;
            ProbeResult {
                reachable: true,
                status_code: None,
                latency_ms,
                target: target_url.to_string(),
                message: format!("TCP 端口已连通 ({}ms)", latency_ms),
            }
        }
        Err(e) => ProbeResult {
            reachable: false,
            status_code: None,
            latency_ms: start.elapsed().as_millis() as u64,
            target: target_url.to_string(),
            message: format!("读取 HTTP 探测响应超时或失败: {}", e),
        },
    }
}

fn focus_main_window<R: Runtime>(app: &AppHandle<R>) {
    if let Some(win) = app.get_webview_window("main") {
        let _ = win.show();
        let _ = win.unminimize();
        let _ = win.set_focus();
    }
}

fn setup_system_tray<R: Runtime>(app: &AppHandle<R>) -> tauri::Result<()> {
    let show_item = MenuItem::with_id(app, "show_main", "显示主窗口", true, None::<&str>)?;
    let separator = PredefinedMenuItem::separator(app)?;
    let quit_item = MenuItem::with_id(app, "quit_app", "退出系统", true, None::<&str>)?;
    let menu = Menu::with_items(app, &[&show_item, &separator, &quit_item])?;

    let mut builder = TrayIconBuilder::with_id("seahorse-tray")
        .tooltip("海马智慧门店 (Seahorse Store) v1.0.0")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app_handle, event| match event.id().as_ref() {
            "show_main" => focus_main_window(app_handle),
            "quit_app" => app_handle.exit(0),
            _ => {}
        })
        .on_tray_icon_event(|tray, event| match event {
            TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            }
            | TrayIconEvent::DoubleClick {
                button: MouseButton::Left,
                ..
            } => {
                focus_main_window(tray.app_handle());
            }
            _ => {}
        });

    if let Some(icon) = app.default_window_icon().cloned() {
        builder = builder.icon(icon);
    }

    let _tray = builder.build(app)?;
    Ok(())
}

#[tauri::command]
fn get_desktop_config() -> Result<DesktopConfig, String> {
    load_or_init_config()
}

#[tauri::command]
fn save_desktop_config(
    api_base_url: Option<String>,
    config: Option<DesktopConfigInput>,
) -> Result<DesktopConfig, String> {
    let resolved = api_base_url
        .or_else(|| config.map(|c| c.api_base_url))
        .ok_or_else(|| "缺少 apiBaseUrl 参数".to_string())?;
    persist_config(&resolved)
}

pub fn collect_desktop_runtime_info() -> DesktopRuntimeInfo {
    DesktopRuntimeInfo {
        product_name: "SeahorseStore".to_string(),
        app_title: "海马智慧门店 (Seahorse Store) v1.0.0".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
        identifier: "com.seahorse.desktop".to_string(),
        os: std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
        family: std::env::consts::FAMILY.to_string(),
        config_dir: config_dir_path().to_string_lossy().to_string(),
        config_path: config_file_path().to_string_lossy().to_string(),
        exe_path: std::env::current_exe()
            .ok()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_default(),
    }
}

#[tauri::command]
fn get_desktop_runtime_info() -> DesktopRuntimeInfo {
    collect_desktop_runtime_info()
}

#[tauri::command]
async fn probe_backend_server(
    api_base_url: Option<String>,
    timeout_ms: Option<u64>,
) -> Result<ProbeResult, String> {
    let target = match api_base_url
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
    {
        Some(url) => url,
        None => load_or_init_config()?.api_base_url,
    };
    let wait_ms = timeout_ms.unwrap_or(3500);

    tauri::async_runtime::spawn_blocking(move || probe_endpoint_blocking(&target, wait_ms))
        .await
        .map_err(|e| format!("探测任务执行异常: {}", e))
}

#[tauri::command]
fn show_main_window(window: Window) -> Result<(), String> {
    let _ = window.show();
    let _ = window.unminimize();
    let _ = window.set_focus();
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            let _ = load_or_init_config();
            setup_system_tray(app.handle())?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_desktop_config,
            save_desktop_config,
            get_desktop_runtime_info,
            probe_backend_server,
            show_main_window
        ])
        .run(tauri::generate_context!())
        .expect("error while running SeahorseStore desktop application");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_api_base_url() {
        assert_eq!(DEFAULT_API_BASE_URL, "https://fwpt.cn/api");
        assert_eq!(
            normalize_api_base_url("  https://fwpt.cn/api/  ").unwrap(),
            "https://fwpt.cn/api"
        );
        assert_eq!(
            normalize_api_base_url("  https://fwpt.cn/seahorse/api/  ").unwrap(),
            "https://fwpt.cn/api"
        );
        assert_eq!(
            normalize_api_base_url("http://127.0.0.1:8082/api").unwrap(),
            "http://127.0.0.1:8082/api"
        );
        assert!(normalize_api_base_url("").is_err());
        assert!(normalize_api_base_url("ftp://example.com").is_err());
    }

    #[test]
    fn test_parse_endpoint_variants() {
        let p1 = parse_endpoint("https://fwpt.cn/api/").unwrap();
        assert_eq!(p1.scheme, "https");
        assert_eq!(p1.host, "fwpt.cn");
        assert_eq!(p1.port, 443);
        assert_eq!(p1.base_path, "/api");

        let p2 = parse_endpoint("http://127.0.0.1:8082/api").unwrap();
        assert_eq!(p2.scheme, "http");
        assert_eq!(p2.host, "127.0.0.1");
        assert_eq!(p2.port, 8082);
        assert_eq!(p2.base_path, "/api");

        let p3 = parse_endpoint("http://[::1]:8082/api").unwrap();
        assert_eq!(p3.host, "::1");
        assert_eq!(p3.port, 8082);

        let p4 = parse_endpoint("https://store.example.com/custom/api/").unwrap();
        assert_eq!(p4.scheme, "https");
        assert_eq!(p4.host, "store.example.com");
        assert_eq!(p4.port, 443);
        assert_eq!(p4.base_path, "/custom/api");
    }

    #[test]
    fn test_runtime_info_fields() {
        let info = get_desktop_runtime_info();
        assert_eq!(info.product_name, "SeahorseStore");
        assert_eq!(info.identifier, "com.seahorse.desktop");
        assert_eq!(info.version, "1.0.0");
        assert!(!info.os.is_empty());
        assert!(!info.arch.is_empty());
    }
}

