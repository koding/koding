fs       = require 'fs'
gulp     = require 'gulp'
shell    = require 'gulp-shell'
argv     = require('minimist') process.argv
siteName = argv.siteName or false
{log}    = require './helper.logger'


module.exports = (siteName) ->

  return log 'red', 'NO SITENAME GIVEN!'  unless siteName

  siteName    = siteName.replace 'site.', ''
  packageJSON = {
    "name"        : "#{siteName}",
    "version"     : "0.1.0",
    "description" : "#{siteName} page for Koding",
  }

  rootPath = "#{__dirname}/../site.boilerplate/"
  sitePath = "#{__dirname}/../site.#{siteName}/"

  json = JSON.stringify(packageJSON)
  commands = [
    "rsync -avq #{rootPath} #{sitePath}"
    "printf '#{json}' > #{__dirname}/../site.#{siteName}/package.json"
  ]

  log 'green', "Copying from #{rootPath} to #{sitePath}"

  gulp.src "#{__dirname}/../static/a/site.boilerplate/js/pistachio.js"
    .pipe shell commands
    .pipe gulp.dest "#{__dirname}/../static/a/site.#{siteName}/js/"
