#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HarmonyOS NEXT Dual-Mode Production Signing Configurator (Stdlib Only).

Reads GitHub Actions / CI environment variables:
  - SEAHORSE_OHOS_P12_BASE64
  - SEAHORSE_OHOS_CER_BASE64
  - SEAHORSE_OHOS_P7B_BASE64
  - SEAHORSE_OHOS_STORE_PASSWORD
  - SEAHORSE_OHOS_KEY_ALIAS
  - SEAHORSE_OHOS_KEY_PASSWORD
  - SEAHORSE_OHOS_BUNDLE_NAME (optional)

Behavior:
  - Signed mode: When P12, CER, and P7B Base64 variables are present, decodes
    certificates into `ohos/signing/` (gitignored) and injects the `release`
    HarmonyOS signingConfig into `ohos/build-profile.json5` (and updates
    `bundleName` in `ohos/AppScope/app.json5` if SEAHORSE_OHOS_BUNDLE_NAME is set).
  - Unsigned fallback mode: When empty, leaves `signingConfigs: []` untouched
    so `flutter build hap --release` / `hvigorw assembleHap` produces a clean
    unsigned `.hap` package, and exits 0.
"""

from __future__ import annotations

import argparse
import base64
import binascii
import json
import os
import re
import shutil
import sys
from pathlib import Path


def _strip_json5_to_json(raw: str) -> str:
    """Minimal JSON5 comment & trailing-comma stripper using Python stdlib."""
    out: list[str] = []
    i = 0
    n = len(raw)
    in_str = False
    quote_char = ""
    while i < n:
        ch = raw[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(raw[i + 1])
                i += 2
                continue
            if ch == quote_char:
                in_str = False
            i += 1
            continue

        if ch in ('"', "'"):
            in_str = True
            quote_char = ch
            out.append(ch)
            i += 1
            continue

        if ch == "/" and i + 1 < n and raw[i + 1] == "/":
            i += 2
            while i < n and raw[i] not in ("\r", "\n"):
                i += 1
            continue

        if ch == "/" and i + 1 < n and raw[i + 1] == "*":
            i += 2
            while i + 1 < n and not (raw[i] == "*" and raw[i + 1] == "/"):
                i += 1
            i += 2
            continue

        out.append(ch)
        i += 1

    cleaned = "".join(out)
    cleaned = re.sub(r",\s*([}\]])", r"\1", cleaned)
    return cleaned


def _load_json5(path: Path) -> dict:
    raw = path.read_text(encoding="utf-8")
    return json.loads(_strip_json5_to_json(raw))


def _write_json5(path: Path, data: dict) -> None:
    rendered = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    path.write_text(rendered, encoding="utf-8", newline="\n")


def _decode_base64_to_file(b64_value: str, dest: Path, label: str) -> int:
    compact = re.sub(r"\s+", "", b64_value)
    try:
        payload = base64.b64decode(compact, validate=True)
    except (binascii.Error, ValueError):
        payload = base64.b64decode(compact)
    if not payload:
        raise ValueError(f"{label} decoded to 0 bytes.")
    dest.write_bytes(payload)
    return len(payload)


def _append_github_env(key: str, value: str) -> None:
    gh_env = os.environ.get("GITHUB_ENV", "").strip()
    if gh_env:
        with open(gh_env, "a", encoding="utf-8", newline="\n") as fh:
            fh.write(f"{key}={value}\n")


def configure_signing(ohos_dir: Path) -> int:
    build_profile_path = ohos_dir / "build-profile.json5"
    app_json_path = ohos_dir / "AppScope" / "app.json5"
    signing_dir = ohos_dir / "signing"

    if not build_profile_path.is_file():
        print(f"[ERROR] Missing HarmonyOS build profile: {build_profile_path}", file=sys.stderr)
        return 1

    p12_b64 = os.environ.get("SEAHORSE_OHOS_P12_BASE64", "").strip()
    cer_b64 = os.environ.get("SEAHORSE_OHOS_CER_BASE64", "").strip()
    p7b_b64 = os.environ.get("SEAHORSE_OHOS_P7B_BASE64", "").strip()
    store_pwd = os.environ.get("SEAHORSE_OHOS_STORE_PASSWORD", "").strip()
    key_alias = os.environ.get("SEAHORSE_OHOS_KEY_ALIAS", "").strip()
    key_pwd = os.environ.get("SEAHORSE_OHOS_KEY_PASSWORD", "").strip() or store_pwd
    bundle_name = os.environ.get("SEAHORSE_OHOS_BUNDLE_NAME", "").strip()

    cert_vars = {
        "SEAHORSE_OHOS_P12_BASE64": bool(p12_b64),
        "SEAHORSE_OHOS_CER_BASE64": bool(cer_b64),
        "SEAHORSE_OHOS_P7B_BASE64": bool(p7b_b64),
    }

    if not any(cert_vars.values()):
        print(
            "[HarmonyOS Signing] No SEAHORSE_OHOS_*_BASE64 secrets detected -> "
            "keeping signingConfigs: [] for graceful unsigned .hap fallback."
        )
        _append_github_env("OHOS_SIGN_MODE", "unsigned")
        return 0

    if not all(cert_vars.values()):
        missing = [k for k, present in cert_vars.items() if not present]
        print(
            f"::warning::Incomplete HarmonyOS signing certificates (missing: {', '.join(missing)}). "
            "Falling back to unsigned .hap build."
        )
        _append_github_env("OHOS_SIGN_MODE", "unsigned")
        return 0

    missing_meta: list[str] = []
    if not store_pwd:
        missing_meta.append("SEAHORSE_OHOS_STORE_PASSWORD")
    if not key_alias:
        missing_meta.append("SEAHORSE_OHOS_KEY_ALIAS")
    if missing_meta:
        print(
            f"::warning::HarmonyOS signing certificates were provided, but {', '.join(missing_meta)} "
            "is empty. Falling back to unsigned .hap build."
        )
        _append_github_env("OHOS_SIGN_MODE", "unsigned")
        return 0

    signing_dir.mkdir(parents=True, exist_ok=True)
    p12_bytes = _decode_base64_to_file(p12_b64, signing_dir / "release.p12", "SEAHORSE_OHOS_P12_BASE64")
    cer_bytes = _decode_base64_to_file(cer_b64, signing_dir / "release.cer", "SEAHORSE_OHOS_CER_BASE64")
    p7b_bytes = _decode_base64_to_file(p7b_b64, signing_dir / "release.p7b", "SEAHORSE_OHOS_P7B_BASE64")

    profile_data = _load_json5(build_profile_path)
    app_section = profile_data.setdefault("app", {})
    app_section["signingConfigs"] = [
        {
            "name": "release",
            "type": "HarmonyOS",
            "material": {
                "certpath": "./signing/release.cer",
                "storePassword": store_pwd,
                "keyAlias": key_alias,
                "keyPassword": key_pwd,
                "profile": "./signing/release.p7b",
                "signAlg": "SHA256withECDSA",
                "storeFile": "./signing/release.p12",
            },
        }
    ]

    products = app_section.get("products")
    if isinstance(products, list) and products:
        products[0]["signingConfig"] = "release"
    else:
        app_section["products"] = [
            {
                "name": "default",
                "signingConfig": "release",
                "compatibleSdkVersion": "5.0.0(12)",
                "runtimeOS": "HarmonyOS",
            }
        ]

    _write_json5(build_profile_path, profile_data)

    if bundle_name and app_json_path.is_file():
        app_data = _load_json5(app_json_path)
        app_data.setdefault("app", {})["bundleName"] = bundle_name
        _write_json5(app_json_path, app_data)
        print(f"[HarmonyOS Signing] Updated AppScope bundleName -> {bundle_name}")

    print(
        "[HarmonyOS Signing] Production signing enabled "
        f"(release.p12={p12_bytes}B, release.cer={cer_bytes}B, release.p7b={p7b_bytes}B, alias={key_alias})."
    )
    _append_github_env("OHOS_SIGN_MODE", "signed")
    return 0


def cleanup_signing(ohos_dir: Path) -> int:
    signing_dir = ohos_dir / "signing"
    if signing_dir.exists():
        shutil.rmtree(signing_dir, ignore_errors=True)
        print(f"[HarmonyOS Signing] Cleaned ephemeral signing directory: {signing_dir}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Configure HarmonyOS NEXT production signing for CI.")
    parser.add_argument(
        "--ohos-dir",
        default=str(Path(__file__).resolve().parent),
        help="Path to the Flutter ohos directory (defaults to script parent directory).",
    )
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="Remove decoded ohos/signing/ certificate artifacts.",
    )
    args = parser.parse_args()
    ohos_dir = Path(args.ohos_dir).resolve()

    if args.cleanup:
        return cleanup_signing(ohos_dir)
    return configure_signing(ohos_dir)


if __name__ == "__main__":
    sys.exit(main())
