#![allow(unknown_lints, linker_messages)]

use seahorse_desktop_lib::{
    collect_desktop_runtime_info, normalize_api_base_url, parse_endpoint, DEFAULT_API_BASE_URL,
};

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
    let info = collect_desktop_runtime_info();
    assert_eq!(info.product_name, "SeahorseStore");
    assert_eq!(info.identifier, "com.seahorse.desktop");
    assert_eq!(info.version, "1.0.0");
    assert!(!info.os.is_empty());
    assert!(!info.arch.is_empty());
}
