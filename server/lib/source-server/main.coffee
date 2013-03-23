{argv} = require 'optimist'

express = require 'express'
app = express()
app.use "/", express.static('client')
app.listen argv.p
console.log "[SOURCEMAP SERVER] running on port #{argv.p} pid:#{process.pid}"