{projectRoot}   = KONFIG
fs              = require 'fs'

defaultIndex    = "#{projectRoot}/website/default.html"
defaultTemplate = fs.readFileSync defaultIndex, 'utf-8'

errorPath       = "#{projectRoot}/website/error.html"
errorTemplate   = fs.readFileSync errorPath, 'utf-8'

notFoundPath       = "#{projectRoot}/website/404.html"
notFoundTemplate   = fs.readFileSync notFoundPath, 'utf-8'

module.exports = {defaultTemplate, errorTemplate, notFoundTemplate}
