fs             = require 'fs'
del            = require 'del'
merge          = require 'merge-stream'
argv           = require('minimist') process.argv

gulp           = require 'gulp'
gutil          = require 'gulp-util'
debug          = require 'gulp-debug'
rename         = require 'gulp-rename'
watch          = require 'gulp-watch'
styleHelper    = require './gulptasks/style'
concat         = require 'gulp-concat'

devMode        = argv.devMode?
version        = argv.ver? or 1

log            = (color, message) -> gutil.log gutil.colors[color] message

module.exports = (opts) ->

  files = []
  folders = opts.modules
  BUILD_PATH = opts.outdir

  gulp.task 'clean', (callback) -> del ["#{BUILD_PATH}/css/*.*.css", "#{BUILD_PATH}/sprites/*", "#{__dirname}/.sprites/*"], force : yes, callback

  gulp.task 'styles-kd', ->

    mainStream = gulp.src "#{__dirname}/node_modules/kd.js/dist/kd.css"
      .pipe gulp.dest "#{BUILD_PATH}/"

    # we need to serve the .map file as well for development - sy
    # currently we don't have it under dist

    # if devMode
    #   mapStream = gulp.src "#{__dirname}/node_modules/kd.js/dist/kd.css.map"
    #     .pipe gulp.dest "#{BUILD_PATH}/css/"

    #   return merge [mainStream, mapStream]

    # else
    #   return mainStream

  unf = "AN-UNFORTUNATE-5-SECS-FOR-SPRITE-FILES-TO-BE-WRITTEN"

  gulp.task 'styles', ['clean', 'styles-kd', 'sprites', unf], ->

    return merge folders.map (folder) ->

      appfnPath = "#{__dirname}/app/lib/styl/appfn.styl"

      compile = ->
        src = [ "./#{folder}/lib/**/*.styl", "!#{appfnPath}" ]
        includes = [ appfnPath ]

        [1,2].forEach (i) ->
          path = "#{__dirname}/.sprites/#{folder}/sprite@#{i}x.styl"
          try includes.push path  if fs.statSync path

        stream = styleHelper {
          fileName : "#{folder}.css"
          includes
          folder
          src
        }

        stream.pipe gulp.dest "#{BUILD_PATH}"
        return stream

      if devMode
        watch [ "#{__dirname}/#{folder}/**/*.styl", "!#{appfnPath}" ]
        , read : no
        , compile

      return compile()


  gulp.task unf, ['sprites'], (cb) -> setTimeout cb, 5000

  gulp.task 'sprites', ['clean'], ->

    return merge folders.map (folder) ->

      return merge [1,2].map (pixelRatio) ->

        generate = (pr) ->
          stream = require('./gulptasks/sprite') folder, pr
          stream.css.pipe gulp.dest "#{__dirname}/.sprites/#{folder}/"
          stream.img.pipe gulp.dest "#{BUILD_PATH}/"
          return stream

        if devMode
          watch ["#{folder}/sprites/#{pixelRatio}x/**/*"]
          , read : no
          , generate.bind(null, pixelRatio)

        return generate pixelRatio

  # this is a helper task for copying folders
  # not a part of the builder
  gulp.task 'copy', ->

    return merge folders.map (folder) ->
      gulp.src ["./#{folder}/**/*"], base : "./#{folder}/lib/"
        .pipe debug title: 'unicorn:'
        .pipe gulp.dest "./../client3/#{folder}/"

  gulp.task 'clean-stuff', (callback) ->
    del ["#{__dirname}/**/lib/styl/sprite@*x.styl"], callback


  gulp.task 'lowercase', ->

      return merge folders.map (folder) ->
        gulp.src ["./#{folder}/**/*.coffee"], base : "./#{folder}/lib/"
          .pipe rename (path, file) ->
            contents = file.contents.toString()
            n = (/class\s([A-Z]{1}\w+)/.exec contents)?[0]
            name = n.replace 'class ', ''  if n
            console.log name.toLowerCase() if name



          # .pipe debug title: 'unicorn:'
          # .pipe gulp.dest "./../client3/#{folder}/"
