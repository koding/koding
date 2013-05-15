{projectRoot} = KONFIG
fs = require 'fs'

defaultIndex = "#{projectRoot}/website/default.html"
page = fs.readFileSync defaultIndex, 'utf-8'

module.exports = (roles=[])->
  page.replace '<!--KONFIG-->', KONFIG.getConfigScriptTag {roles}
