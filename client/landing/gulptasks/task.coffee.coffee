gulp           = require 'gulp'
gulpBuffer     = require 'gulp-buffer'
gulpStream     = require 'gulp-stream'
gulpif         = require 'gulp-if'
source         = require 'vinyl-source-stream'
pistachio      = require 'gulp-kd-pistachio-compiler'
livereload     = require 'gulp-livereload'
argv           = require('minimist') process.argv
devMode        = argv.devMode?

gulpBrowserify = require './helper.browserify'

{
  BUILD_PATH
  BROWSERFIY_PATH
} = require './helper.constants'

module.exports = ->

  gulpBrowserify
      entries : BROWSERFIY_PATH
    .pipe source 'main.js'
    .pipe gulpBuffer()
    .pipe pistachio()
    .pipe gulpStream()
    .pipe gulpif devMode, livereload()
    .pipe gulp.dest "#{BUILD_PATH}/js"
