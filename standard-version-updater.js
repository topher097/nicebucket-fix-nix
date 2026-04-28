const TOML = require('@iarna/toml')
const detectIndent = require('detect-indent')
const detectNewlineModule = require('detect-newline')

const detectNewline = detectNewlineModule.detectNewline || detectNewlineModule.default || detectNewlineModule

module.exports.readVersion = function (contents) {
  return TOML.parse(contents).package.version
}

module.exports.writeVersion = function (contents, version) {
  const parsed = TOML.parse(contents)
  parsed.package.version = version
  const newline = detectNewline(contents) || '\n'
  return TOML.stringify(parsed).replace(/\n/g, newline)
}
