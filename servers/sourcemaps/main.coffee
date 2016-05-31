express = require 'express'

KONFIG = require 'koding-config-manager'

process.title = 'koding-sourcemapserver'

app = express()
app.use '/sourcemaps/', express.static('client')
app.listen KONFIG.sourcemaps.port
console.log "[SOURCEMAP SERVER] running on port #{KONFIG.sourcemaps.port} pid:#{process.pid}"
