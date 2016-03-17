gulp       = require 'gulp'
stylus     = require 'gulp-stylus'
nib        = require 'nib'
concat     = require 'gulp-concat'
rename     = require 'gulp-rename'
gulpif     = require 'gulp-if'
livereload = require 'gulp-livereload'
argv       = require('minimist') process.argv
devMode    = argv.devMode?

{ BUILD_PATH, STYLES_PATH } = require './helper.constants'

module.exports = ->

  gulp.src STYLES_PATH
    .pipe stylus
      compress  : yes
      use       : nib()
      sourcemap : { inline  : yes }  if devMode
    .pipe concat 'main.css'
    .pipe rename 'main.css'
    .pipe gulpif devMode, livereload()
    .pipe gulp.dest "#{BUILD_PATH}/css"
