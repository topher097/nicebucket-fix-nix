module.exports = {
  packageFiles: ['package.json'],
  bumpFiles: [
    'package.json',
    { filename: 'src-tauri/tauri.conf.json', type: 'json' },
    { filename: 'src-tauri/Cargo.toml', updater: './standard-version-updater.js' }
  ]
}
