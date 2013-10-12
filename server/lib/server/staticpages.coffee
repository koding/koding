{projectRoot}   = KONFIG
fs              = require 'fs'

errorPath            = "#{projectRoot}/website/error.html"
errorTemplate        = fs.readFileSync errorPath, 'utf-8'

authRegisterPath     = "#{projectRoot}/website/authRegister.html"
authRegisterTemplate = fs.readFileSync authRegisterPath, 'utf-8'

module.exports = {errorTemplate, authRegisterTemplate}
