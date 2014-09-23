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

  cmd      = "cp -Rf #{rootPath} #{sitePath}"

  log 'green', "Copying from #{rootPath} to #{sitePath}"

  gulp.src ''
    .pipe shell [cmd]
