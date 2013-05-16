{projectRoot} = KONFIG
fs = require 'fs'

defaultIndex = "#{projectRoot}/website/default.html"
defaultTpl = fs.readFileSync defaultIndex, 'utf-8'

module.exports = defaultTpl