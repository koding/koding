{ projectRoot } = KONFIG
fs              = require 'fs'

authRegisterPath     = "#{projectRoot}/website/authRegister.html"
authRegisterTemplate = fs.readFileSync authRegisterPath, 'utf-8'

errorPath            = "#{projectRoot}/website/error.html"
errorTemplate        = fs.readFileSync errorPath, 'utf-8'

notFoundPath       = "#{projectRoot}/website/404.html"
notFoundTemplate   = fs.readFileSync notFoundPath, 'utf-8'

module.exports = { errorTemplate, notFoundTemplate, authRegisterTemplate }
