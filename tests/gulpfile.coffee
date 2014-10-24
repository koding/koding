gulp   = require 'gulp'
coffee = require 'gulp-coffee'


gulp.task 'default', ->
  gulp.src './src/**/*.coffee'
  .pipe coffee()
  .pipe gulp.dest './output/'
