fs = require 'fs'
toml = require('toml-js')

module.exports.create = (KONFIG) ->

  tomlConfig = toml.dump KONFIG.socialapi

  fileName = "./go/src/socialapi/config/#{KONFIG.configName}.toml"
  fs.writeFileSync fileName, tomlConfig

  console.log "socialapi config is written successfully to #{fileName} from KONFIG.socialapi\n"

  return tomlConfig
