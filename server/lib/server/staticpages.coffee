{projectRoot}   = KONFIG
fs              = require 'fs'
defaultIndex    = "#{projectRoot}/website/default.html"
defaultTemplate = fs.readFileSync defaultIndex, 'utf-8'

errorPath            = "#{projectRoot}/website/error.html"
errorTemplate        = fs.readFileSync errorPath, 'utf-8'

authRegisterPath     = "#{projectRoot}/website/authRegister.html"
authRegisterTemplate = fs.readFileSync authRegisterPath, 'utf-8'

module.exports = {defaultTemplate,  errorTemplate, authRegisterTemplate}
