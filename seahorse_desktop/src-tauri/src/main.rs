#![allow(unknown_lints, linker_messages)]
// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    seahorse_desktop_lib::run();
}
