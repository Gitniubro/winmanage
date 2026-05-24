
use tauri_plugin_sql::{Migration, MigrationKind};

pub fn migrations() -> Vec<Migration> {
    vec![
        Migration {
            version: 1,
            description: "create_initial_tables",
            sql: "",
            kind: MigrationKind::Up,
        },
        Migration {
            version: 2,
            description: "create_initial_tables_v2",
            sql: include_str!("migrations.sql"),
            kind: MigrationKind::Up,
        },
    ]
}
