fn main() {
    tauri_build::build();

    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        if let Ok(out_dir) = std::env::var("OUT_DIR") {
            let out = std::path::Path::new(&out_dir);
            for name in ["libresource.a", "resource.lib"] {
                let candidate = out.join(name);
                if candidate.exists() {
                    println!("cargo:rustc-link-arg-tests={}", candidate.display());
                    break;
                }
            }
        }
    }
}
