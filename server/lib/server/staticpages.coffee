{projectRoot}   = KONFIG
fs              = require 'fs'

errorPath       = "#{projectRoot}/website/error.html"
errorTemplate   = fs.readFileSync errorPath, 'utf-8'

module.exports = {errorTemplate}
