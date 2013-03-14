express = require 'express'
app = express()
app.use "/", express.static('client')
app.listen 1337
console.log "[SOURCEMAP SERVER] running on port 1337 pid:#{process.pid}"