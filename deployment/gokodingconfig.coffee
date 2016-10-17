fs = require 'fs'

module.exports.create = (KONFIG)->

  fileName = "./go/src/koding/config/config.json"
  fs.writeFileSync fileName, JSON.stringify KONFIG.socialapi

  console.log "go koding configuration file was successfully written to #{fileName} from KONFIG.goKoding\n"

