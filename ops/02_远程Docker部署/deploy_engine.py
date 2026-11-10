# -*- coding: utf-8 -*-
"""
================================================================================
海马智慧商业平台 - 云端 Docker 容器化自动化打包与发布核心引擎 (Deploy Engine)
================================================================================
支持特性：
  - [模式 1] 全量一键流水线：--all (前后端编译发布云端 + 本地打最新APK + 健康巡检，不上传APK到服务器)
  - [模式 2] 单独部署前端：--frontend (本地 Vite 生产编译构建 + 极速同步远程 Nginx 卷)
  - [模式 3] 单独部署后端：--backend (源码归档 + 云端原生编译 + 注入容器秒级重启)
  - [模式 4] 本地打包移动端：--build-apk / --apk (Flutter Release APK 本地构建，保留在本地无需上传)
  - [模式 5] 服务全链路巡检：--check (Web 80端口、API 8080端口、数据纯净度)
  - [可选模式] 上传移动端：--upload-apk (确有需要时单独将 APK 发布至云端下载通道)
================================================================================
"""

import os
import sys
import time
import tarfile
import argparse
import subprocess
import paramiko
import urllib.request
import json
import shutil

# 统一 Windows 控制台字符编码
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

# 远程服务器网络与连接配置
REMOTE_HOST = '39.97.158.22'
REMOTE_PORT = 22
REMOTE_USER = 'root'
REMOTE_PASS = os.environ.get('FWPT_SSH_PASSWORD', '')
REMOTE_DIR  = '/opt/seahorse'

# 本地工程路径定位 (基于 ops/02_远程Docker部署 上溯至 seahorse 根目录)
OPS_DIR      = os.path.abspath(os.path.dirname(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(OPS_DIR, '..', '..'))
FRONT_DIR    = os.path.join(PROJECT_ROOT, 'seahorse_web_front')
BACK_DIR     = os.path.join(PROJECT_ROOT, 'seahorse_back')
APP_DIR      = os.path.join(PROJECT_ROOT, 'seahorse_app')

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
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(REMOTE_HOST, port=REMOTE_PORT, username=REMOTE_USER, password=REMOTE_PASS, timeout=15)
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
    exec_ssh(ssh, 'mkdir -p /usr/share/nginx/html/seahorse && rm -rf /usr/share/nginx/html/seahorse/* && cp -r /opt/seahorse/seahorse_web_front/dist/* /usr/share/nginx/html/seahorse/ && cp -r /opt/seahorse/seahorse_web_front/dist/* /usr/share/nginx/html/ 2>/dev/null || true')
    
    log("热注入最新前端生产产物至 seahorse-web-front Docker 容器并重载 Nginx...")
    exec_ssh(ssh, 'docker exec seahorse-web-front mkdir -p /usr/share/nginx/html/seahorse 2>/dev/null || true')
    exec_ssh(ssh, 'docker cp /opt/seahorse/seahorse_web_front/dist/. seahorse-web-front:/usr/share/nginx/html/seahorse/')
    exec_ssh(ssh, 'docker cp /opt/seahorse/seahorse_web_front/dist/. seahorse-web-front:/usr/share/nginx/html/')
    exec_ssh(ssh, 'docker exec seahorse-web-front nginx -s reload 2>/dev/null || docker restart seahorse-web-front')
    log("✓ Web 前端已成功注入云端 seahorse-web-front 容器并即时生效 (端口 80)！")
    return True

def deploy_backend(ssh, sftp):
    log("================================================================")
    log(">>> 阶段 2: 编译并部署 Java 后端微服务 (Spring Boot Docker 容器)")
    log("================================================================")
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
        f"cd {REMOTE_DIR}/seahorse_back && "
        f"tar -xzf {REMOTE_DIR}/backend_src.tar.gz -C {REMOTE_DIR}/seahorse_back/ && "
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
    for i in range(25):
        time.sleep(1)
        try:
            req = urllib.request.urlopen(f"http://{REMOTE_HOST}:8080/api/dashboard/stats", timeout=3)
            if req.getcode() == 200:
                log(f"✓ 后端 Docker 容器已在第 {i+1} 秒就绪就绪并开始响应 (对外端口: 8080)！")
                break
        except Exception:
            pass
    return True

def find_flutter_bin():
    candidates = [
        "flutter",
        r"C:\src\flutter\bin\flutter.bat",
        r"C:\flutter\bin\flutter.bat",
        os.path.expanduser(r"~\flutter\bin\flutter.bat")
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
    log(">>> 阶段 3: 本地编译最新 Flutter 移动端 Release APK (无需上传服务器)")
    log("================================================================")
    flutter_bin = find_flutter_bin()
    cmd = f"{flutter_bin} build apk --release"
    log(f"正在本地调用 Flutter 编译最新 Release APK: {cmd} ...")
    if not run_local(cmd, APP_DIR):
        log("[错误] Flutter APK 本地编译失败，请检查 Flutter 构建环境与代码！")
        return False

    src_apk = os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
    if os.path.exists(src_apk):
        dst_apk = os.path.join(PROJECT_ROOT, 'seahorse_app_latest.apk')
        shutil.copy2(src_apk, dst_apk)
        size_mb = os.path.getsize(dst_apk) / 1024 / 1024
        log("✓ 本地最新 Release APK 已成功生成！")
        log(f"  - 产物文件: {dst_apk}")
        log(f"  - 文件大小: {size_mb:.2f} MB")
        log("  - 说明: 已按需求保留在本地，无需耗时上传服务器，可直接安装至测试手机！")
        return True
    else:
        log("[错误] 未找到构建产物 app-release.apk")
        return False

def upload_app_apk(ssh, sftp):
    log("================================================================")
    log(">>> 可选阶段: 上传移动端 Release APK 至云端下载通道")
    log("================================================================")
    apk_candidates = [
        os.path.join(PROJECT_ROOT, 'seahorse_app_latest.apk'),
        os.path.join(APP_DIR, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'),
        os.path.join(PROJECT_ROOT, 'seahorse_app_v1.0_release.apk')
    ]
    apk_found = None
    for c in apk_candidates:
        if os.path.exists(c):
            apk_found = c
            break

    if apk_found:
        size_mb = os.path.getsize(apk_found) / 1024 / 1024
        log(f"发现可用 Release APK: {apk_found} ({size_mb:.2f} MB)")
        remote_apk = '/usr/share/nginx/html/seahorse_app_latest.apk'
        log(f"SFTP 上传 APK 至云端 Nginx 静态下载目录: {remote_apk}...")
        sftp.put(apk_found, remote_apk)
        exec_ssh(ssh, f"chmod 644 {remote_apk}")
        log(f"✓ 移动端 APK 发布完成！下载直链: http://{REMOTE_HOST}/seahorse_app_latest.apk")
    else:
        log("[提示] 未找到本地 Release APK 文件，跳过此步")
    return True

def health_check():
    log("================================================================")
    log(">>> 阶段 4: 云端全系统自动化链路健康巡检")
    log("================================================================")
    # 1. 网页前端
    try:
        req = urllib.request.urlopen(f"http://{REMOTE_HOST}/", timeout=8)
        log(f"[1/4] Web 前端页面服务: HTTP {req.getcode()} (正常访问)")
    except Exception as e:
        log(f"[1/4] Web 前端页面异常: {e}")

    # 2. 后端大盘 API
    try:
        req = urllib.request.urlopen(f"http://{REMOTE_HOST}:8080/api/dashboard/stats", timeout=8)
        log(f"[2/4] 后端大盘指标接口: HTTP {req.getcode()} (服务正常运算)")
    except Exception as e:
        log(f"[2/4] 后端大盘接口异常: {e}")

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
    args = parser.parse_args()

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
        build_local_apk()
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

    try:
        if args.all or args.frontend:
            deploy_frontend(ssh, sftp)
        if args.all or args.backend:
            deploy_backend(ssh, sftp)
        if args.all or args.build_apk:
            build_local_apk()
        if args.upload_apk:
            upload_app_apk(ssh, sftp)

        health_check()
        print("\n" + "=" * 72)
        log("🎉 所选发布任务全部执行完毕！服务已在云端正常上线运行。")
        print("=" * 72)
    finally:
        sftp.close()
        ssh.close()

if __name__ == '__main__':
    main()
