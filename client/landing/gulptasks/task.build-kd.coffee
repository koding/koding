gulp    = require 'gulp'
shell   = require 'gulp-shell'
argv    = require('minimist') process.argv
devMode = argv.devMode?

{ BUILD_PATH } = require './helper.constants'

module.exports = ->

  base           = "#{__dirname}/.."
  kdGulpFilePath = "#{base}/node_modules/kdf/gulpfile.coffee"

  gulp.src ''
    .pipe shell [
      "cp -f #{base}/site.#{SITE_NAME}/coffee/entry.coffee #{base}/node_modules/kdf/src/entry.coffee"
      "gulp --gulpfile #{kdGulpFilePath} compile #{if devMode then '' else '--uglify'} --entryPath=#{base}/node_modules/kdf/src/entry.coffee --outputDir=#{BUILD_PATH}"
    ]
