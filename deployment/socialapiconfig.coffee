fs = require 'fs'
toml = require('toml-js');

module.exports.create = (KONFIG)->

  tomlConfig = toml.dump KONFIG.socialapi

  fs.writeFileSync "./go/src/socialapi/config/#{KONFIG.configName}.toml", tomlConfig

  return tomlConfig
