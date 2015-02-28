gulp           = require 'gulp'
stylus         = require 'gulp-stylus'
nib            = require 'nib'
concat         = require 'gulp-concat'
gulpif         = require 'gulp-if'
notify         = require 'gulp-notify'
# livereload     = require 'gulp-livereload'
argv           = require('minimist') process.argv
devMode        = argv.devMode?

module.exports = ({src, fileName, includes}) ->

  options           = use : nib()
  options.compress  = yes           unless devMode
  options.import    = includes      if includes
  options.sourcemap = inline : yes  if devMode

  stream = gulp.src src
    .pipe stylus options
    .pipe concat fileName

  if devMode
    stream
      .pipe notify
        title    : 'Styles compiled'
        message  : "#{fileName}"
        icon     : "#{__dirname}/../assets/stylus.png"
      # .pipe gulpif devMode, livereload()

  return stream
