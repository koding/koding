gulp    = require 'gulp'
shell   = require 'gulp-shell'

module.exports = (version) ->
  gulp.src ''
    .pipe shell 'gulp --gulpfile ./site.landing/gulpfile.coffee build --uglify'
