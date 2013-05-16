{projectRoot} = KONFIG
fs = require 'fs'

defaultIndex = "#{projectRoot}/website/default.html"
defaultTemplate = fs.readFileSync defaultIndex, 'utf-8'

module.exports = defaultTemplate