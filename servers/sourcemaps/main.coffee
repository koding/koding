{argv} = require 'optimist'
process.title = 'koding-sourcemapserver'

express = require 'express'
app = express()
app.use "/", express.static('client')
app.listen argv.p
console.log "[SOURCEMAP SERVER] running on port #{argv.p} pid:#{process.pid}"
