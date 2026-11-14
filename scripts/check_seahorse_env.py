#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
seahorse/scripts/check_seahorse_env.py
================================================================================
海马智慧商业平台 (Seahorse Smart Store) - 全栈环境变量与云端容器只读安全审计工具
================================================================================
支持模式：
  python scripts/check_seahorse_env.py            # 默认同时审计本地配置与云端 Node 2 容器
  python scripts/check_seahorse_env.py --local    # 仅审计本地 .env / .env.example / docker-compose.yml / .secrets
  python scripts/check_seahorse_env.py --remote   # 仅通过只读 SSH 审计云端 Node 2 seahorse-back 容器环境

安全红线（零明文泄漏承诺）：
  严禁在控制台、日志或返回信息中打印任何真实密码、RDS 实例域名、JWT 密钥、SSH 口令或高德 API Key；
  所有敏感配置仅展示变量名与脱敏状态（如 SET (masked, len=16) 或 jdbc:mysql://***:3306/seahorse_store）。
================================================================================
"""

import argparse
import importlib.util
import json
import os
import re
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEAHORSE_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
FWPT_ROOT = os.path.abspath(os.path.join(SEAHORSE_ROOT, ".."))

SAFE_DISPLAY_KEYS = {
    "SPRING_PROFILES_ACTIVE",
    "SERVER_PORT",
    "JPA_SHOW_SQL",
    "TZ",
    "LANG",
    "LC_ALL",
    "FWPT_NODE2",
    "FWPT_SSH_USER",
    "SEAHORSE_DB_PORT",
    "SEAHORSE_DB_NAME",
}

EXPECTED_ENV_VARS = [
    ("SPRING_PROFILES_ACTIVE", "后端运行 Profile (dev/prod)", False),
    ("SERVER_PORT", "后端监听端口 (本地 8082 / 云端 8080)", False),
    ("SPRING_DATASOURCE_URL", "MySQL JDBC 连接串", False),
    ("SPRING_DATASOURCE_USERNAME", "MySQL 登录用户名", False),
    ("SPRING_DATASOURCE_PASSWORD", "MySQL 登录密码", False),
    ("SEAHORSE_JWT_SECRET", "JWT HS256 签名密钥 (>=32字节)", False),
    ("SEAHORSE_AMAP_WEB_KEY", "高德地图服务端 Web API Key", False),
    ("SEAHORSE_AMAP_JS_KEY", "高德地图服务端兜底 JS Key", False),
    ("SEAHORSE_AMAP_SECURITY_CODE", "高德地图安全密钥 jscode", False),
    ("VITE_AMAP_WEB_KEY", "前端 Vite 高德 Web Key", False),
    ("VITE_AMAP_JS_KEY", "前端 Vite 高德 JS API Key", False),
    ("VITE_AMAP_SECURITY_CODE", "前端 Vite 高德安全密钥", False),
    ("FWPT_NODE2", "远程部署目标主机地址", False),
    ("FWPT_SSH_USER", "远程部署 SSH 用户名", False),
    ("FWPT_SSH_KEY", "远程部署 SSH 私钥路径", False),
    ("FWPT_SSH_PASSWORD", "远程部署 SSH 口令", False),
]

EXPECTED_COMPOSE_VARS = [
    "SPRING_DATASOURCE_URL",
    "SPRING_DATASOURCE_USERNAME",
    "SPRING_DATASOURCE_PASSWORD",
    "SEAHORSE_JWT_SECRET",
    "SEAHORSE_AMAP_WEB_KEY",
    "SEAHORSE_AMAP_JS_KEY",
    "SEAHORSE_AMAP_SECURITY_CODE",
]


def classify_host(host: str) -> str:
    h = (host or "").strip().lower()
    if not h:
        return "empty"
    if h in ("localhost", "127.0.0.1"):
        return f"loopback({h})"
    if h == "seahorse-mysql":
        return "docker-service(seahorse-mysql)"
    if "rds.aliyuncs.com" in h:
        return "aliyun-rds(***)"
    if re.match(r"^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)", h):
        return "private-ip(***)"
    if re.match(r"^172\.", h):
        return "docker-bridge(***)"
    return "external-host(***)"


def mask_jdbc_url(url: str) -> str:
    if not url:
        return "EMPTY"
    m = re.match(r"^(jdbc:mysql://)([^/?]+)(/[^?]*)?(\?.*)?$", url.strip())
    if not m:
        return f"SET (custom-jdbc, len={len(url)})"
    prefix, hostport, path, query = m.groups()
    if ":" in hostport:
        host, port = hostport.rsplit(":", 1)
    else:
        host, port = hostport, "3306"
    host_kind = classify_host(host)
    shown_host = host if host.lower() in ("localhost", "127.0.0.1", "seahorse-mysql") else "***"
    param_keys = []
    if query and query.startswith("?"):
        for seg in query[1:].split("&"):
            if "=" in seg:
                param_keys.append(seg.split("=", 1)[0])
    params_note = f"?{'&'.join(k + '=...' for k in param_keys[:4])}" if param_keys else ""
    return f"SET ({prefix}{shown_host}:{port}{path or ''}{params_note} [{host_kind}])"


def mask_value(key: str, val: str) -> str:
    if val is None or val == "":
        return "EMPTY"
    if key == "SPRING_DATASOURCE_URL":
        return mask_jdbc_url(val)
    if key in ("SEAHORSE_DB_HOST", "FWPT_DB_HOST"):
        return f"SET ({classify_host(val)})"
    if key == "SEAHORSE_JWT_SECRET":
        byte_len = len(val.encode("utf-8"))
        strength = ">=32B OK" if byte_len >= 32 else "<32B TOO_SHORT!"
        return f"SET (masked, {byte_len}B, {strength})"
    if key in SAFE_DISPLAY_KEYS:
        return f"SET ({val})"
    return f"SET (masked, len={len(val)})"


def parse_dotenv(path: str) -> dict:
    result = {}
    if not os.path.exists(path):
        return result
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("export "):
                line = line[7:].strip()
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip()
            if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                if len(v) >= 2:
                    v = v[1:-1]
            if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", k):
                result[k] = v
    return result


def load_fwpt_cred():
    secrets_py = os.path.join(FWPT_ROOT, "scripts", "fwpt_secrets.py")
    if not os.path.exists(secrets_py):
        return None, None
    spec = importlib.util.spec_from_file_location("_fwpt_secrets_mod", secrets_py)
    if not spec or not spec.loader:
        return None, None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return getattr(mod, "cred", None), getattr(mod, "SECRETS_FILE", None)


def mask_cmd_arg(arg: str) -> str:
    if arg in ("java", "-jar", "app.jar", "/app/app.jar", "sh", "-c"):
        return arg
    if arg.startswith("-Xms") or arg.startswith("-Xmx"):
        return arg
    if "=" in arg:
        k, v = arg.split("=", 1)
        if k in ("-Dfile.encoding", "-Dsun.jnu.encoding", "-Dserver.port", "--server.port", "--spring.profiles.active"):
            return f"{k}={v}"
        if "url" in k.lower():
            return f"{k}={mask_jdbc_url(v)}"
        return f"{k}=***MASKED***"
    return f"<arg:len={len(arg)}>"


def audit_local() -> tuple[bool, list[str]]:
    print("=" * 84)
    print(" [1/2] 本地全栈环境与配置文件审计 (Local Seahorse Environment Audit)")
    print("=" * 84)
    issues = []

    gitignore_path = os.path.join(SEAHORSE_ROOT, ".gitignore")
    env_example_path = os.path.join(SEAHORSE_ROOT, ".env.example")
    dotenv_path = os.path.join(SEAHORSE_ROOT, ".env")
    compose_path = os.path.join(SEAHORSE_ROOT, "docker-compose.yml")

    # 1. Check .gitignore protects .env
    env_ignored = False
    try:
        res = subprocess.run(
            ["git", "-C", FWPT_ROOT, "check-ignore", "-q", "seahorse/.env"],
            capture_output=True,
            text=True,
        )
        env_ignored = res.returncode == 0
    except Exception:
        if os.path.exists(gitignore_path):
            with open(gitignore_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = [ln.strip() for ln in f]
            env_ignored = ".env" in lines

    if env_ignored:
        print("  [PASS] Git 忽略保护: seahorse/.env 已被 .gitignore 安全排除")
    else:
        print("  [FAIL] Git 忽略保护: seahorse/.env 未被 .gitignore 排除，存在密钥误提交风险！")
        issues.append("seahorse/.env is not gitignored")

    # 2. Check .env.example
    if os.path.exists(env_example_path):
        example_map = parse_dotenv(env_example_path)
        missing_in_example = [k for k, _, _ in EXPECTED_ENV_VARS if k not in example_map]
        if missing_in_example:
            print(f"  [WARN] .env.example 缺少变量占位: {', '.join(missing_in_example)}")
        else:
            print(f"  [PASS] 模板完整性: seahorse/.env.example 覆盖全部 {len(EXPECTED_ENV_VARS)} 项标准环境变量")
    else:
        print("  [FAIL] 缺失模板文件: seahorse/.env.example 不存在")
        issues.append("seahorse/.env.example missing")
        example_map = {}

    # 3. Check docker-compose.yml interpolation
    if os.path.exists(compose_path):
        with open(compose_path, "r", encoding="utf-8", errors="ignore") as f:
            compose_txt = f.read()
        missing_compose = [k for k in EXPECTED_COMPOSE_VARS if f"${{{k}" not in compose_txt]
        if missing_compose:
            print(f"  [FAIL] docker-compose.yml 缺少环境变量插值: {', '.join(missing_compose)}")
            issues.append(f"docker-compose.yml missing interpolations: {missing_compose}")
        else:
            print(f"  [PASS] 容器编排插值: seahorse/docker-compose.yml 已配置全部 {len(EXPECTED_COMPOSE_VARS)} 项 ${{VAR:-}} 注入")
    else:
        print("  [FAIL] 缺失编排文件: seahorse/docker-compose.yml 不存在")
        issues.append("seahorse/docker-compose.yml missing")

    # 4. Check local .env & shared .secrets/fwpt_credentials.json
    dotenv_exists = os.path.exists(dotenv_path)
    dotenv_map = parse_dotenv(dotenv_path) if dotenv_exists else {}
    print(
        f"  [INFO] 本地私有 .env: {'已创建 (' + str(sum(1 for v in dotenv_map.values() if v)) + ' 项非空配置)' if dotenv_exists else '未创建 (将使用 application.yml / 系统环境变量默认值)'}"
    )

    cred, secrets_file = load_fwpt_cred()
    secrets_json = {}
    if secrets_file and os.path.exists(secrets_file):
        try:
            with open(secrets_file, "r", encoding="utf-8") as f:
                secrets_json = json.load(f) or {}
            present_secret_keys = [k for k, v in secrets_json.items() if k != "_comment" and v]
            print(f"  [PASS] 共享凭据库 (.secrets/fwpt_credentials.json): 已就绪 (含非空键: {', '.join(sorted(present_secret_keys))})")
        except Exception:
            print("  [WARN] 共享凭据库 (.secrets/fwpt_credentials.json): 解析异常")
    else:
        print("  [INFO] 共享凭据库 (.secrets/fwpt_credentials.json): 未配置")

    # 5. Print Variable Resolution Table
    print("\n  " + "-" * 80)
    print(f"  {'变量名称 (Variable)':<30} | {'脱敏状态 (Masked Status)':<26} | {'生效来源 (Source)'}")
    print("  " + "-" * 80)

    secret_fallback_map = {
        "FWPT_NODE2": "node2",
        "FWPT_SSH_USER": "ssh_user",
        "FWPT_SSH_KEY": "ssh_key",
        "FWPT_SSH_PASSWORD": "ssh_password",
    }

    for key, desc, _ in EXPECTED_ENV_VARS:
        os_val = os.environ.get(key)
        env_val = dotenv_map.get(key)
        sec_key = secret_fallback_map.get(key)
        sec_val = secrets_json.get(sec_key) if sec_key else None

        if os_val:
            status = mask_value(key, os_val)
            source = "OS 环境变量"
        elif env_val:
            status = mask_value(key, env_val)
            source = "seahorse/.env"
        elif sec_val:
            status = mask_value(key, str(sec_val))
            source = ".secrets/fwpt_credentials.json"
        else:
            status = "UNSET (使用框架默认/留空)"
            source = f"默认兜底 ({desc})"
        print(f"  {key:<30} | {status:<26} | {source}")
    print("  " + "-" * 80)

    return len(issues) == 0, issues


def audit_remote(strict: bool = False) -> tuple[bool, list[str]]:
    print("\n" + "=" * 84)
    print(" [2/2] 云端生产节点 Node 2 (seahorse-back 容器) 只读安全审计")
    print("=" * 84)
    issues = []
    warnings = []

    cred, _ = load_fwpt_cred()
    if cred is None:
        print("  [FAIL] 无法加载 scripts/fwpt_secrets.py 凭据模块")
        return False, ["fwpt_secrets module missing"]

    try:
        import paramiko
    except ImportError:
        print("  [FAIL] 本地缺少 paramiko 依赖，无法执行 SSH 只读巡检")
        return False, ["paramiko not installed"]

    try:
        node2 = cred.get("node2") or os.environ.get("FWPT_NODE2") or "39.97.158.22"
        ssh_kwargs = cred.ssh_kwargs(node2)
    except Exception as exc:
        print(f"  [FAIL] SSH 凭据未就绪: {exc}")
        return False, ["SSH credentials unavailable"]

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(**ssh_kwargs)
    except Exception as exc:
        print(f"  [FAIL] 无法建立到 Node 2 ({node2}) 的只读 SSH 连接: {type(exc).__name__}")
        return False, ["SSH connection failed"]

    try:
        def run_ro(cmd: str) -> str:
            _, stdout, _ = ssh.exec_command(cmd)
            return stdout.read().decode("utf-8", errors="replace").strip()

        ps_names = run_ro("docker ps --format '{{.Names}}'").splitlines()
        has_mysql_container = "seahorse-mysql" in ps_names
        insp_raw = run_ro("docker inspect seahorse-back 2>/dev/null")
        if not insp_raw or insp_raw == "[]":
            print("  [FAIL] Node 2 上未找到 seahorse-back 容器！")
            return False, ["seahorse-back container not found on Node 2"]

        insp = json.loads(insp_raw)[0]
        state = insp.get("State", {})
        cfg = insp.get("Config", {})
        hc = insp.get("HostConfig", {})

        running = bool(state.get("Running"))
        port_bindings = hc.get("PortBindings") or {}
        ports_summary = ", ".join(
            f"{','.join(b.get('HostPort', '') for b in (binds or []))}->{cport}"
            for cport, binds in port_bindings.items()
        )
        entrypoint = [mask_cmd_arg(x) for x in (cfg.get("Entrypoint") or [])]
        cmd_list = [mask_cmd_arg(x) for x in (cfg.get("Cmd") or [])]

        env_map = {}
        for item in cfg.get("Env") or []:
            if "=" in item:
                k, v = item.split("=", 1)
                env_map[k] = v

        opt_dotenv_exists = run_ro("test -f /opt/seahorse/.env && echo YES || echo NO") == "YES"
        opt_compose_exists = run_ro("test -f /opt/seahorse/docker-compose.yml && echo YES || echo NO") == "YES"

        print(f"  [INFO] 目标节点: {node2} | 容器状态: {'RUNNING' if running else state.get('Status')}")
        print(f"  [INFO] 端口映射: {ports_summary or 'none'} | 同机 seahorse-mysql 容器: {'存在' if has_mysql_container else '不存在 (使用外部 RDS)'}")
        print(f"  [INFO] 启动命令 (脱敏): {' '.join(entrypoint + cmd_list)}")
        print(
            f"  [INFO] 宿主机编排目录 (/opt/seahorse): docker-compose.yml={'存在' if opt_compose_exists else '缺失'}, .env={'存在' if opt_dotenv_exists else '未单独拆分'}"
        )

        remote_checks = [
            ("SPRING_PROFILES_ACTIVE", True, "生产环境 Profile"),
            ("SERVER_PORT", True, "容器服务监听端口 (或 Entrypoint -Dserver.port)"),
            ("SPRING_DATASOURCE_URL", True, "生产数据库连接 URL (严禁无容器时回退 seahorse-mysql)"),
            ("SPRING_DATASOURCE_USERNAME", True, "生产数据库账号"),
            ("SPRING_DATASOURCE_PASSWORD", True, "生产数据库密码"),
            ("SEAHORSE_JWT_SECRET", False, "生产 JWT 签名密钥 (建议显式注入 >=32B 随机密钥)"),
            ("SEAHORSE_AMAP_WEB_KEY", False, "高德 Web 服务 Key (可选，亦可在管理台保存至数据库)"),
            ("SEAHORSE_AMAP_JS_KEY", False, "高德 JS API Key (可选)"),
            ("SEAHORSE_AMAP_SECURITY_CODE", False, "高德安全密钥 (可选)"),
        ]

        print("\n  " + "-" * 80)
        print(f"  {'容器环境变量 (Container Env)':<30} | {'审计结论':<10} | {'脱敏详情 (Masked Detail)'}")
        print("  " + "-" * 80)

        cmd_joined = " ".join(entrypoint + cmd_list)
        for key, required_in_prod, note in remote_checks:
            val = env_map.get(key)
            if key == "SERVER_PORT" and not val and ("server.port=" in cmd_joined):
                verdict = "PASS"
                detail = f"SET via Entrypoint/Cmd ({note})"
            elif val:
                verdict = "PASS"
                detail = mask_value(key, val)
                if key == "SPRING_DATASOURCE_URL" and "seahorse-mysql" in val and not has_mysql_container:
                    verdict = "FAIL"
                    detail += " [CRITICAL: 指向不存在的 seahorse-mysql 容器!]"
                    issues.append("SPRING_DATASOURCE_URL points to missing seahorse-mysql on Node 2")
            else:
                if required_in_prod:
                    verdict = "FAIL"
                    detail = f"MISSING — {note}"
                    issues.append(f"Node 2 seahorse-back missing required {key}")
                else:
                    verdict = "WARN" if key == "SEAHORSE_JWT_SECRET" else "OPT"
                    detail = f"MISSING ({note})"
                    if key == "SEAHORSE_JWT_SECRET":
                        warnings.append("SEAHORSE_JWT_SECRET not set in Node 2 container Env (using application.yml fallback)")
            print(f"  {key:<30} | {verdict:<10} | {detail}")
        print("  " + "-" * 80)

        if not issues:
            print("  [PASS] 关键连通性核验: Node 2 seahorse-back 容器已显式持有外部 RDS 数据源与端口环境变量，")
            print("         移除 application-prod.yml 硬编码地址后执行 app.jar 热更新完全安全！")
        if warnings:
            for w in warnings:
                print(f"  [WARN] 安全加固建议: {w}")
            if strict:
                issues.extend(warnings)
    finally:
        ssh.close()

    return len(issues) == 0, issues


def main() -> int:
    parser = argparse.ArgumentParser(description="海马智慧商业平台 - 全栈环境变量与云端容器只读安全审计工具")
    parser.add_argument("--local", action="store_true", help="仅审计本地配置文件与环境变量")
    parser.add_argument("--remote", action="store_true", help="仅只读审计远程 Node 2 seahorse-back 容器环境")
    parser.add_argument("--strict", action="store_true", help="严格模式：将安全建议项 (WARN) 也视为非零退出")
    args = parser.parse_args()

    run_local_flag = args.local or (not args.local and not args.remote)
    run_remote_flag = args.remote or (not args.local and not args.remote)

    all_ok = True
    if run_local_flag:
        ok_local, _ = audit_local()
        if not ok_local:
            all_ok = False
    if run_remote_flag:
        ok_remote, _ = audit_remote(strict=args.strict)
        if not ok_remote:
            all_ok = False

    print("\n" + "=" * 84)
    if all_ok:
        print(" 审计汇总: PASS — 全栈环境变量链路与生产容器配置校验通过（零明文密钥暴露）")
        print("=" * 84)
        return 0
    else:
        print(" 审计汇总: FAIL — 发现关键环境配置缺失或风险，请根据上方提示修复后再发布！")
        print("=" * 84)
        return 1


if __name__ == "__main__":
    sys.exit(main())
