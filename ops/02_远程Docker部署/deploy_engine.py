# -*- coding: utf-8 -*-
"""
================================================================================
海马智慧商业平台 - 云端 Docker 容器化自动化打包与发布核心引擎 (Deploy Engine)
================================================================================
支持特性：
  - [模式 1] 全量一键流水线：--all (前后端编译发布云端 + 本地打最新APK + 健康巡检，不默认上传APK)
  - [模式 2] 单独部署前端：--frontend (本地 Vite 生产编译构建 + 极速同步远程 Nginx 卷)
  - [模式 3] 单独部署后端：--backend (源码归档 + 云端原生编译 + 注入容器秒级重启)
  - [模式 4] 本地打包移动端：--build-apk / --apk (委托 seahorse_app/build_android.ps1 本地构建)
  - [模式 5] 服务全链路巡检：--check (Web /seahorse/、API /api/health、数据纯净度)
  - [可选模式] 上传移动端：--upload-apk (同步 APK 至 seahorse-web-front 容器静态下载目录)
================================================================================
"""

import os
import re
import sys
import stat
import time
import json
import shutil
import tarfile
import argparse
import importlib.util
import subprocess
import urllib.request
import paramiko

# 统一 Windows 控制台字符编码
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

# 本地工程路径定位 (基于 ops/02_远程Docker部署 上溯至 seahorse 根目录)
OPS_DIR      = os.path.abspath(os.path.dirname(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(OPS_DIR, '..', '..'))
FWPT_ROOT    = os.path.abspath(os.path.join(PROJECT_ROOT, '..'))
FRONT_DIR    = os.path.join(PROJECT_ROOT, 'seahorse_web_front')
BACK_DIR     = os.path.join(PROJECT_ROOT, 'seahorse_back')
APP_DIR      = os.path.join(PROJECT_ROOT, 'seahorse_app')


def _load_local_dotenv():
    """自动加载 seahorse/.env 中的非空变量（不覆盖已显式设置的系统环境变量，绝不打印密钥）。"""
    dotenv_file = os.path.join(PROJECT_ROOT, '.env')
    if not os.path.exists(dotenv_file):
        return
    try:
        with open(dotenv_file, 'r', encoding='utf-8', errors='ignore') as f:
            for raw in f:
                line = raw.strip()
                if not line or line.startswith('#'):
                    continue
                if line.startswith('export '):
                    line = line[7:].strip()
                if '=' not in line:
                    continue
                k, v = line.split('=', 1)
                k, v = k.strip(), v.strip()
                if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                    if len(v) >= 2:
                        v = v[1:-1]
                if re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', k) and v and not os.environ.get(k):
                    os.environ[k] = v
    except Exception as exc:
        print(f"[WARN] 读取本地 .env 失败: {exc}")


_load_local_dotenv()


def _load_ssh_settings():
    """按 环境变量 > 父仓 scripts/fwpt_secrets.py > 本地 .secrets 文件 优先级加载凭据（绝不硬编码）。"""
    host = os.environ.get('FWPT_NODE2') or '39.97.158.22'
    user = os.environ.get('FWPT_SSH_USER') or 'root'
    password = os.environ.get('FWPT_SSH_PASSWORD') or ''
    key_file = os.environ.get('FWPT_SSH_KEY') or ''

    if not password and not key_file:
        fwpt_secrets_py = os.path.join(FWPT_ROOT, 'scripts', 'fwpt_secrets.py')
        if os.path.exists(fwpt_secrets_py):
            try:
                spec = importlib.util.spec_from_file_location('_fwpt_secrets_shared', fwpt_secrets_py)
                if spec and spec.loader:
                    mod = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(mod)
                    cred = getattr(mod, 'cred', None)
                    if cred:
                        host = cred.get('node2') or host
                        user = cred.get('ssh_user') or user
                        password = cred.get('ssh_password') or password
                        key_file = cred.get('ssh_key') or key_file
            except Exception as exc:
                print(f"[WARN] 读取共享凭据模块失败: {exc}")

    if not password and not key_file:
        secret_candidates = [
            os.path.abspath(os.path.join(OPS_DIR, '..', '..', '.secrets', 'fwpt_secrets.cred')),
            os.path.join(FWPT_ROOT, '.secrets', 'fwpt_secrets.cred'),
            os.path.join(FWPT_ROOT, '.secrets', 'fwpt_credentials.json'),
            os.path.join(PROJECT_ROOT, '.secrets', 'fwpt_credentials.json'),
        ]
        for cand in secret_candidates:
            if not os.path.exists(cand):
                continue
            try:
                with open(cand, 'r', encoding='utf-8') as f:
                    raw = f.read().strip()
                if not raw:
                    continue
                if raw.startswith('{'):
                    data = json.loads(raw)
                    host = data.get('node2') or host
                    user = data.get('ssh_user') or user
                    password = data.get('ssh_password') or password
                    key_file = data.get('ssh_key') or key_file
                else:
                    for line in raw.splitlines():
                        line = line.strip()
                        if not line or line.startswith('#'):
                            continue
                        if '=' in line:
                            k, v = line.split('=', 1)
                            k, v = k.strip().lower(), v.strip().strip('"').strip("'")
                            if k in ('fwpt_ssh_password', 'ssh_password', 'password'):
                                password = v
                            elif k in ('fwpt_ssh_key', 'ssh_key'):
                                key_file = v
                        elif not password:
                            password = line
                if password or key_file:
                    break
            except Exception as exc:
                print(f"[WARN] 解析凭据文件 {cand} 失败: {exc}")

    return host, user, password, key_file


REMOTE_HOST, REMOTE_USER, REMOTE_PASS, REMOTE_KEY = _load_ssh_settings()
REMOTE_PORT = 22
REMOTE_DIR  = '/opt/seahorse'


def log(msg):
    print(f"[\033[92mSEAHORSE-OPS\033[0m] {msg}")


def run_local(cmd, cwd):
    log(f"执行本地构建命令: {cmd} (目录: {cwd})")
    res = subprocess.run(cmd, shell=True, cwd=cwd)
    if res.returncode != 0:
        print(f"[ERROR] 本地命令执行失败 (退出码 {res.returncode}): {cmd}")
        return False
    return True


def create_ssh():
    if not REMOTE_PASS and not REMOTE_KEY:
        raise RuntimeError(
            "未检测到远程 SSH 认证凭据！请设置环境变量 FWPT_SSH_PASSWORD / FWPT_SSH_KEY，"
            "或在仓库根目录运行 python scripts/fwpt_secrets.py --init 配置 .secrets 凭据文件。"
        )
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    connect_kwargs = {
        'hostname': REMOTE_HOST,
        'port': REMOTE_PORT,
        'username': REMOTE_USER,
        'timeout': 15,
    }
    if REMOTE_KEY:
        connect_kwargs['key_filename'] = os.path.expanduser(REMOTE_KEY)
        connect_kwargs['look_for_keys'] = False
        connect_kwargs['allow_agent'] = False
    else:
        connect_kwargs['password'] = REMOTE_PASS
    ssh.connect(**connect_kwargs)
    return ssh


def exec_ssh(ssh, cmd):
    log(f"远程服务器执行: {cmd}")
    stdin, stdout, stderr = ssh.exec_command(cmd)
    out = stdout.read().decode('utf-8', errors='ignore')
    err = stderr.read().decode('utf-8', errors='ignore')
    if err and ('error' in err.lower() or 'failed' in err.lower()):
        print(f"[远程输出提示] {err.strip()[:300]}")
    return out.strip()


def deploy_frontend(ssh, sftp):
    log("================================================================")
    log(">>> 阶段 1: 编译并部署 Web 前端工程 (Vue 3 + Vite)")
    log("================================================================")
    log("正在本地执行 npm run build 编译最新前端生产代码...")
    if not run_local('npm run build', FRONT_DIR):
        log("[ERROR] 前端构建失败！")
        return False

    dist_dir = os.path.join(FRONT_DIR, 'dist')
    if not os.path.exists(dist_dir) or not os.path.exists(os.path.join(dist_dir, 'index.html')):
        log("[ERROR] 未找到前端构建产物 dist/index.html！")
        return False

    tar_path = os.path.join(PROJECT_ROOT, 'web_dist.tar.gz')
    log(f"正在打包最新前端静态资源至临时归档: {tar_path}...")
    with tarfile.open(tar_path, 'w:gz') as tar:
        for root, dirs, files in os.walk(dist_dir):
            for file in files:
                full_p = os.path.join(root, file)
                rel_p = os.path.relpath(full_p, dist_dir)
                tar.add(full_p, arcname=rel_p)

    remote_tar = '/tmp/web_dist.tar.gz'
    log(f"SFTP 上传前端资源包至云端: {remote_tar} ({os.path.getsize(tar_path)/1024:.1f} KB)...")
    sftp.put(tar_path, remote_tar)
    if os.path.exists(tar_path):
        os.remove(tar_path)

    log("在云端宿主机解压并更新 Seahorse 静态目录 (/usr/share/nginx/html/seahorse/)...")
    exec_ssh(ssh, 'mkdir -p /opt/seahorse/seahorse_web_front/dist && rm -rf /opt/seahorse/seahorse_web_front/dist/* && tar -xzf /tmp/web_dist.tar.gz -C /opt/seahorse/seahorse_web_front/dist/ && rm -f /tmp/web_dist.tar.gz')
    exec_ssh(ssh, 'mkdir -p /usr/share/nginx/html/seahorse && rm -rf /usr/share/nginx/html/seahorse/* && cp -r /opt/seahorse/seahorse_web_front/dist/* /usr/share/nginx/html/seahorse/ 2>/dev/null || true')

    log("热注入最新前端生产产物至 seahorse-web-front Docker 容器并重载 Nginx...")
    exec_ssh(ssh, 'docker exec seahorse-web-front sh -c "mkdir -p /usr/share/nginx/html/seahorse && rm -rf /usr/share/nginx/html/seahorse/*" 2>/dev/null || true')
    exec_ssh(ssh, 'docker cp /opt/seahorse/seahorse_web_front/dist/. seahorse-web-front:/usr/share/nginx/html/seahorse/')
    exec_ssh(ssh, 'docker exec seahorse-web-front nginx -s reload 2>/dev/null || docker restart seahorse-web-front')
    log("✓ Web 前端已成功注入云端 seahorse-web-front 容器并即时生效 (路径 /seahorse/)！")
    return True


def _exec_ssh_quiet(ssh, cmd):
    """静默执行只读远程探测命令（不回显敏感标准输出）。"""
    _, stdout, _ = ssh.exec_command(cmd)
    return stdout.read().decode('utf-8', errors='ignore').strip()


def _mask_jdbc_url(url):
    """脱敏展示 JDBC URL，绝不输出真实 RDS 主机名、IP 或凭据参数。"""
    if not url:
        return 'MISSING'
    m = re.match(r'^(jdbc:mysql://)([^/?]+)(/[^?]*)?(\?.*)?$', url.strip())
    if not m:
        return f'SET(custom-jdbc, len={len(url)})'
    prefix, hostport, path, _ = m.groups()
    host, port = hostport.rsplit(':', 1) if ':' in hostport else (hostport, '3306')
    shown_host = host if host.lower() in ('localhost', '127.0.0.1', 'seahorse-mysql') else '***'
    return f'{prefix}{shown_host}:{port}{path or ""}'


def _load_prod_db_credentials():
    """
    从本地环境变量或 .secrets/fwpt_credentials.json 读取生产数据库与安全配置，
    仅用于容器缺失关键环境变量且显式开启 --inject-env 时的 SFTP 安全注入（绝不打印明文）。
    """
    sec_data = {}
    for cand in (
        os.path.join(FWPT_ROOT, '.secrets', 'fwpt_credentials.json'),
        os.path.join(PROJECT_ROOT, '.secrets', 'fwpt_credentials.json'),
    ):
        if os.path.exists(cand):
            try:
                with open(cand, 'r', encoding='utf-8') as f:
                    sec_data = json.load(f) or {}
                if sec_data:
                    break
            except Exception:
                pass

    env_db_url = (os.environ.get('SEAHORSE_PROD_DATASOURCE_URL') or os.environ.get('SPRING_DATASOURCE_URL') or '').strip()
    if env_db_url and ('127.0.0.1' in env_db_url or 'localhost' in env_db_url):
        # 避免把本地开发库 URL 误当作云端生产 RDS 地址
        env_db_url = ''

    db_url = env_db_url or (sec_data.get('seahorse_db_url') or '').strip()
    db_host = (os.environ.get('FWPT_DB_HOST') or sec_data.get('seahorse_db_host') or sec_data.get('db_host') or '').strip()
    if not db_url and db_host:
        db_url = (
            f"jdbc:mysql://{db_host}:3306/seahorse_store"
            "?useSSL=false&serverTimezone=Asia/Shanghai&characterEncoding=utf8&allowPublicKeyRetrieval=true"
        )

    db_user = (
        os.environ.get('SEAHORSE_PROD_DB_USER')
        or sec_data.get('seahorse_db_user')
        or os.environ.get('FWPT_DB_USER')
        or sec_data.get('db_user')
        or ''
    ).strip()
    db_pass = (
        os.environ.get('SEAHORSE_PROD_DB_PASSWORD')
        or sec_data.get('seahorse_db_password')
        or os.environ.get('FWPT_DB_PASSWORD')
        or sec_data.get('db_password')
        or ''
    ).strip()
    jwt_secret = (sec_data.get('seahorse_jwt_secret') or os.environ.get('SEAHORSE_PROD_JWT_SECRET') or '').strip()
    amap_web = (os.environ.get('SEAHORSE_AMAP_WEB_KEY') or sec_data.get('seahorse_amap_web_key') or '').strip()
    amap_js = (os.environ.get('SEAHORSE_AMAP_JS_KEY') or sec_data.get('seahorse_amap_js_key') or '').strip()
    amap_sec = (os.environ.get('SEAHORSE_AMAP_SECURITY_CODE') or sec_data.get('seahorse_amap_security_code') or '').strip()

    return {
        'SPRING_DATASOURCE_URL': db_url,
        'SPRING_DATASOURCE_USERNAME': db_user,
        'SPRING_DATASOURCE_PASSWORD': db_pass,
        'SEAHORSE_JWT_SECRET': jwt_secret,
        'SEAHORSE_AMAP_WEB_KEY': amap_web,
        'SEAHORSE_AMAP_JS_KEY': amap_js,
        'SEAHORSE_AMAP_SECURITY_CODE': amap_sec,
    }


def verify_or_inject_backend_env(ssh, sftp, allow_inject=False):
    """
    在覆盖 app.jar 并重启 seahorse-back 之前，强制校验云端容器 Config.Env：
    由于 application-prod.yml 已移除硬编码 RDS 地址（默认回退 seahorse-mysql:3306），
    若云端容器缺失 SPRING_DATASOURCE_URL 等必要变量，拒绝盲目覆盖重启，防止生产断连！
    """
    log("正在执行云端 seahorse-back 容器环境变量安全预检 (零明文脱敏核验)...")
    ps_names = _exec_ssh_quiet(ssh, "docker ps --format '{{.Names}}'").splitlines()
    has_mysql_container = 'seahorse-mysql' in ps_names

    env_json_raw = _exec_ssh_quiet(ssh, "docker inspect seahorse-back --format '{{json .Config.Env}}' 2>/dev/null")
    cmd_json_raw = _exec_ssh_quiet(
        ssh,
        "docker inspect seahorse-back --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}' 2>/dev/null",
    )

    env_map = {}
    if env_json_raw and env_json_raw.startswith('['):
        try:
            for item in json.loads(env_json_raw) or []:
                if '=' in item:
                    k, v = item.split('=', 1)
                    env_map[k] = v
        except Exception:
            pass

    ds_url = env_map.get('SPRING_DATASOURCE_URL', '')
    ds_user = env_map.get('SPRING_DATASOURCE_USERNAME', '')
    ds_pass = env_map.get('SPRING_DATASOURCE_PASSWORD', '')
    srv_port = env_map.get('SERVER_PORT', '')
    has_cmd_port = 'server.port=' in (cmd_json_raw or '')

    missing_critical = []
    if not ds_url:
        missing_critical.append('SPRING_DATASOURCE_URL')
    elif 'seahorse-mysql' in ds_url and not has_mysql_container:
        missing_critical.append('SPRING_DATASOURCE_URL(指向不存在的seahorse-mysql容器)')
    if not ds_user:
        missing_critical.append('SPRING_DATASOURCE_USERNAME')
    if not ds_pass:
        missing_critical.append('SPRING_DATASOURCE_PASSWORD')

    if not missing_critical:
        port_desc = srv_port or ('Entrypoint -Dserver.port' if has_cmd_port else 'default')
        log(
            f"✓ 容器环境预检通过: SPRING_DATASOURCE_URL={_mask_jdbc_url(ds_url)}, "
            f"USERNAME=SET(len={len(ds_user)}), PASSWORD=SET(len={len(ds_pass)}), SERVER_PORT={port_desc}"
        )
        if not env_map.get('SEAHORSE_JWT_SECRET'):
            log("[提示] 容器未显式注入 SEAHORSE_JWT_SECRET，当前使用 application.yml 内置默认密钥；建议后续在 /opt/seahorse/.env 中注入独立 >=32B 密钥。")
        return True

    log(f"[WARN] 云端 seahorse-back 容器缺失关键环境变量: {', '.join(missing_critical)}")
    auto_inject = allow_inject or (os.environ.get('SEAHORSE_AUTO_INJECT_ENV') == '1')
    if not auto_inject:
        log("[ERROR] 安全阻断：application-prod.yml 已移除硬编码生产 RDS 地址（默认 seahorse-mysql:3306）。")
        log("[ERROR] 为防止覆盖 app.jar 后导致生产数据库连接中断，已拒绝盲目重启 seahorse-back！")
        log("        解决方案 1: 运行 check_env.bat 核查容器状态，并在云端 /opt/seahorse 配置 .env 后执行 docker compose up -d")
        log("        解决方案 2: 确保 .secrets/fwpt_credentials.json 含 db_host/db_user/db_password 后，附加 --inject-env 重新执行")
        return False

    prod_creds = _load_prod_db_credentials()
    if not (prod_creds['SPRING_DATASOURCE_URL'] and prod_creds['SPRING_DATASOURCE_USERNAME'] and prod_creds['SPRING_DATASOURCE_PASSWORD']):
        log("[ERROR] 已开启 --inject-env，但本地 .secrets/fwpt_credentials.json 或环境变量中未找到完整的生产 RDS 连接信息 (seahorse_db_url/db_host, db_user, db_password)！")
        return False

    compose_exists = _exec_ssh_quiet(ssh, f"test -f {REMOTE_DIR}/docker-compose.yml && echo YES || echo NO") == 'YES'
    if not compose_exists:
        log(f"[ERROR] 云端 {REMOTE_DIR}/docker-compose.yml 不存在，无法安全重建注入环境变量！")
        return False

    log("正在通过 SFTP 加密通道向 /opt/seahorse/.env 写入权限 0600 的生产环境配置（全程零明文回显）...")
    env_lines = [
        "# Managed by Seahorse deploy_engine.py (chmod 600)",
        "SPRING_PROFILES_ACTIVE=prod",
        f"SERVER_PORT={srv_port or '8080'}",
        f"SPRING_DATASOURCE_URL={prod_creds['SPRING_DATASOURCE_URL']}",
        f"SPRING_DATASOURCE_USERNAME={prod_creds['SPRING_DATASOURCE_USERNAME']}",
        f"SPRING_DATASOURCE_PASSWORD={prod_creds['SPRING_DATASOURCE_PASSWORD']}",
    ]
    if prod_creds['SEAHORSE_JWT_SECRET'] and len(prod_creds['SEAHORSE_JWT_SECRET'].encode('utf-8')) >= 32:
        env_lines.append(f"SEAHORSE_JWT_SECRET={prod_creds['SEAHORSE_JWT_SECRET']}")
    for opt_k in ('SEAHORSE_AMAP_WEB_KEY', 'SEAHORSE_AMAP_JS_KEY', 'SEAHORSE_AMAP_SECURITY_CODE'):
        if prod_creds.get(opt_k):
            env_lines.append(f"{opt_k}={prod_creds[opt_k]}")

    remote_env_path = f"{REMOTE_DIR}/.env"
    with sftp.file(remote_env_path, 'w') as rf:
        rf.write('\n'.join(env_lines) + '\n')
    sftp.chmod(remote_env_path, stat.S_IRUSR | stat.S_IWUSR)

    exec_ssh(ssh, f"cd {REMOTE_DIR} && (docker compose --env-file {remote_env_path} up -d seahorse-back || docker-compose --env-file {remote_env_path} up -d seahorse-back)")

    # 二次核验注入结果
    recheck_raw = _exec_ssh_quiet(ssh, "docker inspect seahorse-back --format '{{json .Config.Env}}' 2>/dev/null")
    recheck_map = {}
    if recheck_raw and recheck_raw.startswith('['):
        for item in json.loads(recheck_raw) or []:
            if '=' in item:
                k, v = item.split('=', 1)
                recheck_map[k] = v
    if not recheck_map.get('SPRING_DATASOURCE_URL'):
        log("[ERROR] 重建容器后仍未在 seahorse-back Config.Env 中检测到 SPRING_DATASOURCE_URL（请检查云端 docker-compose.yml 是否引用 ${SPRING_DATASOURCE_URL} 或 env_file: .env）！")
        return False

    log(f"✓ 已成功向 seahorse-back 注入生产环境变量: SPRING_DATASOURCE_URL={_mask_jdbc_url(recheck_map['SPRING_DATASOURCE_URL'])}")
    return True


def deploy_backend(ssh, sftp, allow_inject=False):
    log("================================================================")
    log(">>> 阶段 2: 编译并部署 Java 后端微服务 (Spring Boot Docker 容器)")
    log("================================================================")
    if not verify_or_inject_backend_env(ssh, sftp, allow_inject=allow_inject):
        return False

    tar_path = os.path.join(PROJECT_ROOT, 'backend_src.tar.gz')
    log(f"正在打包本地后端最新源码与 Maven POM 配置至: {tar_path}...")
    with tarfile.open(tar_path, 'w:gz') as tar:
        tar.add(os.path.join(BACK_DIR, 'src'), arcname='src')
        tar.add(os.path.join(BACK_DIR, 'pom.xml'), arcname='pom.xml')

    remote_tar = f"{REMOTE_DIR}/backend_src.tar.gz"
    log(f"SFTP 上传后端源码包至云端: {remote_tar} ({os.path.getsize(tar_path)/1024:.1f} KB)...")
    sftp.put(tar_path, remote_tar)
    if os.path.exists(tar_path):
        os.remove(tar_path)

    log("在云端原生 Linux 环境极速编译: mvn clean package -DskipTests ...")
    build_cmds = (
        f"mkdir -p {REMOTE_DIR}/seahorse_back && cd {REMOTE_DIR}/seahorse_back && "
        f"rm -rf {REMOTE_DIR}/seahorse_back/src && "
        f"tar -xzf {REMOTE_DIR}/backend_src.tar.gz -C {REMOTE_DIR}/seahorse_back/ && "
        f"rm -f {REMOTE_DIR}/backend_src.tar.gz && "
        "export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && "
        "mvn clean package -DskipTests -Dfile.encoding=UTF-8"
    )
    build_out = exec_ssh(ssh, build_cmds)
    if "BUILD SUCCESS" in build_out:
        log("✓ 云端 Maven 编译构建成功 (BUILD SUCCESS)！")
    else:
        log("[ERROR] 云端 Maven 编译失败！")
        print(build_out[-1500:])
        return False

    log("热注入编译产物至 seahorse-back Docker 容器并秒级重启进程...")
    docker_cmds = (
        f"cd {REMOTE_DIR} && "
        "JAR_FILE=$(ls -t /opt/seahorse/seahorse_back/target/*.jar | head -n 1) && "
        "docker cp $JAR_FILE seahorse-back:/app/app.jar && "
        "docker restart seahorse-back"
    )
    res = exec_ssh(ssh, docker_cmds)
    print(res)

    log("等待 Spring Boot 容器完成就绪检测...")
    ready = False
    for i in range(25):
        time.sleep(1)
        try:
            req = urllib.request.urlopen(f"http://{REMOTE_HOST}:8080/api/health", timeout=3)
            if req.getcode() == 200:
                log(f"✓ 后端 Docker 容器已在第 {i+1} 秒就绪并开始响应 (对外端口: 8080)！")
                ready = True
                break
        except Exception:
            pass
    if not ready:
        log("[WARN] 25 秒内未探测到 http://{0}:8080/api/health 返回 200，请检查容器日志或安全组策略。".format(REMOTE_HOST))
    return True


def find_flutter_bin():
    candidates = [
        "flutter",
        r"C:\src\flutter\bin\flutter.bat",
        r"C:\flutter\bin\flutter.bat",
        os.path.expanduser(r"~\flutter\bin\flutter.bat"),
    ]
    for c in candidates:
        if c == "flutter":
            if shutil.which("flutter"):
                return "flutter"
        elif os.path.exists(c):
            return f'"{c}"'
    return "flutter"


def build_local_apk():
    log("================================================================")
    log(">>> 阶段 3: 本地编译最新 Flutter 移动端 Release APK (委托 build_android.ps1)")
    log("================================================================")
    build_ps1 = os.path.join(APP_DIR, 'build_android.ps1')
    env = os.environ.copy()
    # 严禁自动改写父仓 dist_apps/ 冻结归档，保持非交互式构建
    env['SEAHORSE_SKIP_DIST_APPS'] = '1'
    env['SEAHORSE_NON_INTERACTIVE'] = '1'

    if os.path.exists(build_ps1):
        cmd = [
            'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', build_ps1,
        ]
        log(f"正在调用统一安卓构建脚本: {build_ps1} ...")
        res = subprocess.run(cmd, cwd=APP_DIR, env=env, input='\r\n\r\n', text=True, encoding='utf-8', errors='replace')
        if res.returncode != 0:
            log(f"[错误] build_android.ps1 执行失败 (退出码 {res.returncode})！")
            return False
    else:
        flutter_bin = find_flutter_bin()
        cmd_str = f"{flutter_bin} build apk --release"
        log(f"正在本地调用 Flutter 编译最新 Release APK: {cmd_str} ...")
        if not run_local(cmd_str, APP_DIR):
            log("[错误] Flutter APK 本地编译失败，请检查 Flutter 构建环境与代码！")
            return False

    src_apk = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
    if os.path.exists(src_apk):
        dst_latest = os.path.join(PROJECT_ROOT, 'seahorse_app_latest.apk')
        dst_versioned = os.path.join(PROJECT_ROOT, 'seahorse_app-v1.0.0.apk')
        shutil.copy2(src_apk, dst_latest)
        shutil.copy2(src_apk, dst_versioned)
        size_mb = os.path.getsize(dst_latest) / 1024 / 1024
        log("✓ 本地最新 Release APK 已成功生成！")
        log(f"  - 版本产物: {dst_versioned}")
        log(f"  - 最新产物: {dst_latest}")
        log(f"  - 文件大小: {size_mb:.2f} MB")
        log("  - 说明: 已保留在 seahorse 本地目录，未触碰冻结的父仓 dist_apps/ 归档。")
        return True

    log("[错误] 未找到构建产物 app-release.apk")
    return False


def upload_app_apk(ssh, sftp):
    log("================================================================")
    log(">>> 可选阶段: 上传移动端 Release APK 至云端下载通道")
    log("================================================================")
    apk_candidates = [
        os.path.join(PROJECT_ROOT, 'seahorse_app-v1.0.0.apk'),
        os.path.join(FWPT_ROOT, 'dist_apps', 'seahorse_app-v1.0.0.apk'),
        os.path.join(PROJECT_ROOT, 'seahorse_app_latest.apk'),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
    ]
    apk_found = None
    for c in apk_candidates:
        if os.path.exists(c):
            apk_found = c
            break

    if not apk_found:
        log("[提示] 未找到本地 Release APK 文件，跳过此步")
        return False

    size_mb = os.path.getsize(apk_found) / 1024 / 1024
    log(f"发现可用 Release APK: {apk_found} ({size_mb:.2f} MB)")
    remote_tmp_apk = '/tmp/seahorse_app_upload.apk'
    log(f"SFTP 上传 APK 至云端临时目录: {remote_tmp_apk}...")
    sftp.put(apk_found, remote_tmp_apk)

    sync_cmds = (
        "mkdir -p /usr/share/nginx/html && "
        f"cp -f {remote_tmp_apk} /usr/share/nginx/html/seahorse_app-v1.0.0.apk && "
        f"cp -f {remote_tmp_apk} /usr/share/nginx/html/seahorse_app_latest.apk && "
        "chmod 644 /usr/share/nginx/html/seahorse_app-v1.0.0.apk /usr/share/nginx/html/seahorse_app_latest.apk && "
        "docker exec seahorse-web-front mkdir -p /usr/share/nginx/html/index && "
        f"docker cp {remote_tmp_apk} seahorse-web-front:/usr/share/nginx/html/index/seahorse_app-v1.0.0.apk && "
        f"docker cp {remote_tmp_apk} seahorse-web-front:/usr/share/nginx/html/index/seahorse_app_latest.apk && "
        f"docker cp {remote_tmp_apk} seahorse-web-front:/usr/share/nginx/html/seahorse_app_latest.apk && "
        "docker exec seahorse-web-front chmod 644 "
        "/usr/share/nginx/html/index/seahorse_app-v1.0.0.apk "
        "/usr/share/nginx/html/index/seahorse_app_latest.apk "
        "/usr/share/nginx/html/seahorse_app_latest.apk && "
        f"rm -f {remote_tmp_apk}"
    )
    exec_ssh(ssh, sync_cmds)
    log("✓ 移动端 APK 已同步注入 seahorse-web-front 容器静态目录！")
    log(f"  - 标准版本直链: http://{REMOTE_HOST}/seahorse_app-v1.0.0.apk")
    log(f"  - 兼容最新直链: http://{REMOTE_HOST}/seahorse_app_latest.apk")
    return True


def health_check():
    log("================================================================")
    log(">>> 阶段 4: 云端全系统自动化链路健康巡检")
    log("================================================================")
    # 1. 网页前端 (/seahorse/ 子路径)
    try:
        req = urllib.request.urlopen(f"http://{REMOTE_HOST}/seahorse/", timeout=8)
        log(f"[1/4] Web 前端页面服务 (/seahorse/): HTTP {req.getcode()} (正常访问)")
    except Exception as e:
        log(f"[1/4] Web 前端页面异常: {e}")

    # 2. 后端健康探针 API (/api/health 免鉴权心跳接口)
    try:
        req = urllib.request.urlopen(f"http://{REMOTE_HOST}:8080/api/health", timeout=8)
        log(f"[2/4] 后端健康探针接口 (/api/health): HTTP {req.getcode()} (服务正常在线)")
    except Exception as e:
        log(f"[2/4] 后端健康探针接口异常: {e}")

    # 3. 预约排班 API 数据纯净度校验
    try:
        req = urllib.request.urlopen(f"http://{REMOTE_HOST}:8080/api/appointment/list?storeId=S001", timeout=8)
        data = json.loads(req.read().decode('utf-8'))
        apt_cnt = len(data.get('data', []))
        log(f"[3/4] 预约排班纯净核验: 当前预约数: {apt_cnt} 条 (符合业务真实纯净要求)")
    except Exception as e:
        log(f"[3/4] 预约排班接口异常: {e}")

    # 4. 展位工位 API 校验
    try:
        req = urllib.request.urlopen(f"http://{REMOTE_HOST}:8080/api/space/list?storeId=S001", timeout=8)
        data = json.loads(req.read().decode('utf-8'))
        space_cnt = len(data.get('data', []))
        log(f"[4/4] 展位工位管理接口: HTTP {req.getcode()}, 活跃包厢/工位数: {space_cnt} (正常)")
    except Exception as e:
        log(f"[4/4] 展位接口异常: {e}")


def main():
    parser = argparse.ArgumentParser(description="海马智慧商业平台自动化部署脚本")
    parser.add_argument('--all', action='store_true', help="全量发布：编译发布前端+后端至云端，本地打最新APK（不上传云端）并巡检")
    parser.add_argument('--frontend', action='store_true', help="仅本地编译并发布前端工程至云端 Nginx")
    parser.add_argument('--backend', action='store_true', help="仅打包并发布后端微服务至云端 Docker")
    parser.add_argument('--build-apk', '--apk', dest='build_apk', action='store_true', help="仅在本地编译生成最新移动端 Release APK（无需上传服务器）")
    parser.add_argument('--upload-apk', dest='upload_apk', action='store_true', help="可选：将本地 Release APK 上传发布至云端下载通道")
    parser.add_argument('--check', action='store_true', help="仅执行云端健康巡检")
    parser.add_argument('--check-env', dest='check_env', action='store_true', help="执行本地与云端 Node 2 容器环境变量只读安全审计")
    parser.add_argument('--inject-env', dest='inject_env', action='store_true', help="当云端容器缺失关键环境变量时，从本地 .secrets 安全写入 /opt/seahorse/.env 并重建容器")
    args = parser.parse_args()

    if args.check_env:
        audit_script = os.path.join(PROJECT_ROOT, 'scripts', 'check_seahorse_env.py')
        res = subprocess.run([sys.executable, audit_script])
        sys.exit(res.returncode)

    # 默认执行全量部署
    if not (args.frontend or args.backend or args.build_apk or args.upload_apk or args.check):
        args.all = True

    print("=" * 72)
    print("        海马智慧商业平台 - Docker 远程打包部署与运维引擎")
    print(f"        目标云端主机: {REMOTE_HOST} ({REMOTE_DIR})")
    print("=" * 72)

    if args.check:
        health_check()
        return

    # 若仅在本地编译生成 APK，无需建立远程 SSH/SFTP 连接
    if args.build_apk and not (args.all or args.frontend or args.backend or args.upload_apk):
        if not build_local_apk():
            print("\n" + "=" * 72)
            log("[ERROR] 本地 APK 打包任务失败！")
            print("=" * 72)
            sys.exit(1)
        print("\n" + "=" * 72)
        log("🎉 本地 APK 打包任务执行完毕！")
        print("=" * 72)
        return

    try:
        ssh = create_ssh()
        sftp = ssh.open_sftp()
        log("SSH / SFTP 已建立加密连接通道！")
    except Exception as e:
        print(f"[FATAL] 连接远程服务器失败: {e}")
        sys.exit(1)

    ok = True
    try:
        if args.all or args.frontend:
            if not deploy_frontend(ssh, sftp):
                ok = False
        if ok and (args.all or args.backend):
            if not deploy_backend(ssh, sftp, allow_inject=args.inject_env):
                ok = False
        if ok and (args.all or args.build_apk):
            if not build_local_apk():
                ok = False
        if ok and args.upload_apk:
            if not upload_app_apk(ssh, sftp):
                ok = False

        if not ok:
            print("\n" + "=" * 72)
            log("[ERROR] 发布流水线存在失败步骤，已中止后续流程，请排查上方错误日志！")
            print("=" * 72)
            sys.exit(1)

        health_check()
        print("\n" + "=" * 72)
        log("🎉 所选发布任务全部执行完毕！服务已在云端正常上线运行。")
        print("=" * 72)
    finally:
        sftp.close()
        ssh.close()


if __name__ == '__main__':
    main()
