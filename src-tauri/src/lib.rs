mod keyring;
mod s3;

use specta_typescript::{BigIntExportBehavior, Typescript};
use std::fs::File;
use std::io::{BufRead, BufReader};
use tauri_specta::{collect_commands, Builder};

fn should_set_webkit_workaround() -> bool {
    let is_appimage = std::env::var("APPIMAGE").is_ok();

    if !is_appimage {
        return false;
    }

    #[cfg(target_os = "linux")]
    {
        let is_debian_based = check_if_debian_or_ubuntu();

        !is_debian_based
    }

    #[cfg(not(target_os = "linux"))]
    {
        false
    }
}

#[cfg(target_os = "linux")]
fn check_if_debian_or_ubuntu() -> bool {
    if let Ok(file) = File::open("/etc/os-release") {
        let reader = BufReader::new(file);

        for line in reader.lines().map_while(Result::ok) {
            if let Some((key, value)) = line.split_once('=') {
                let value = value.trim().trim_matches('"');

                // We check "ID" (the specific distro) and "ID_LIKE" (what it is based on).
                // E.g., Linux Mint has ID=linuxmint but ID_LIKE=ubuntu.
                let is_id_key = key == "ID" || key == "ID_LIKE";
                let is_debian_or_ubuntu_value =
                    value.contains("debian") || value.contains("ubuntu");

                if is_id_key && is_debian_or_ubuntu_value {
                    return true;
                }
            }
        }
    }

    false
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let builder = Builder::<tauri::Wry>::new().commands(collect_commands![
        s3::connect_to_s3,
        s3::list_buckets,
        s3::list_objects,
        s3::download_object,
        s3::download_objects,
        s3::delete_objects,
        s3::download_folder,
        s3::delete_folder,
        s3::upload_objects,
        s3::create_folder,
        s3::move_objects,
        keyring::save_connection,
        keyring::load_saved_connections,
        keyring::delete_saved_connection,
        keyring::is_connection_saved,
        keyring::is_connection_duplicate,
    ]);

    #[cfg(debug_assertions)]
    builder
        .export(
            Typescript::new().bigint(BigIntExportBehavior::Number),
            "../src/bindings.ts",
        )
        .expect("Failed to export typescript bindings");

    // This aims at solving issue when running on non-Debian Linux
    if should_set_webkit_workaround() {
        std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");
    }

    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_keyring::init())
        .manage(s3::ConnectionMap::default())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(builder.invoke_handler())
        .setup(move |app| {
            builder.mount_events(app);

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
