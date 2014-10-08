fs      = require 'fs'
gulp    = require 'gulp'
shell   = require 'gulp-shell'


module.exports = ->

  folders  = (folder for folder in fs.readdirSync('./') when fs.statSync(folder).isDirectory())
  sites    = folders.filter (folder) -> folder.search(/^site\./) is 0
  commands = ("gulp --gulpfile ./#{siteDir}/gulpfile.coffee build" for siteDir in sites)

  gulp.src ''
    .pipe shell commands