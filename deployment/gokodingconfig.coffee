fs = require 'fs'

module.exports.create = (KONFIG) ->

  fileName = './go/src/koding/kites/config/config.json'
  fs.writeFileSync fileName, JSON.stringify KONFIG.goKoding

  console.log "go koding configuration file was successfully written to #{fileName} from KONFIG.goKoding\n"
