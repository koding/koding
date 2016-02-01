fs      = require 'fs'
gulp    = require 'gulp'
shell   = require 'gulp-shell'

module.exports = (version) ->

  folders  = (folder for folder in fs.readdirSync('./') when fs.statSync(folder).isDirectory())
  sites    = folders.filter (folder) ->
    siteDir = folder.search(/^site\./) is 0 and folder isnt 'site.boilerplate'
    return no  unless siteDir
    try
      fs.statSync "#{folder}/gulpfile.coffee"
      return yes
    return no
  commands = ("gulp --gulpfile ./#{siteDir}/gulpfile.coffee build --uglify" for siteDir in sites)

  gulp.src ''
    .pipe shell commands
