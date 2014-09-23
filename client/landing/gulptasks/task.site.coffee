gulp  = require 'gulp'
shell = require 'gulp-shell'
argv  = require('minimist') process.argv

{log} = require './helper.logger'


module.exports = ->

  siteName = argv.siteName or false

  return log 'red', 'NO SITENAME GIVEN!'  unless siteName

  siteName = siteName.replace 'site.', ''
  rootPath = "#{__dirname}/../site.boilerplate/"
  sitePath = "#{__dirname}/../site.#{siteName}"

  commands = ["cp -Rf #{rootPath} #{sitePath}"]
  # commands.push "cp -Rf #{__dirname}/../static/a/site.boilerplate/js/pistachio.js #{__dirname}/../static/a/site.#{siteName}/js/pistachio.js"

  log 'green', "Copying from #{rootPath} to #{sitePath}"

  gulp.src "#{__dirname}/../static/a/site.boilerplate/js/pistachio.js"
    .pipe shell commands
    .pipe gulp.dest "#{__dirname}/../static/a/site.#{siteName}/js/"
