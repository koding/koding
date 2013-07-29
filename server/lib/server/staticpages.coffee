{projectRoot}   = KONFIG
fs              = require 'fs'
defaultIndex    = "#{projectRoot}/website/default.html"
defaultTemplate = fs.readFileSync defaultIndex, 'utf-8'

loginPath = "#{projectRoot}/website/login.html"
loginTemplate = fs.readFileSync loginPath, 'utf-8'

loginFailurePath = "#{projectRoot}/website/login_failure.html"
loginFailureTemplate = fs.readFileSync loginFailurePath, 'utf-8'

module.exports = {defaultTemplate, loginTemplate, loginFailureTemplate}
