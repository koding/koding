gulp  = require 'gulp'
shell = require 'gulp-shell'

module.exports = ->

  base           = "#{__dirname}/.."
  kdGulpFilePath = "#{base}/node_modules/kdf/gulpfile.coffee"

  gulp.src ''
    .pipe shell [
      "cp -f #{base}/landing/coffee/entry.coffee #{base}/node_modules/kdf/src/entry.coffee"
      "gulp --gulpfile #{kdGulpFilePath} compile --uglify --entryPath=#{base}/node_modules/kdf/src/entry.coffee --outputDir=#{base}/static/a/out"
    ]
