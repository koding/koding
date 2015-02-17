gulp           = require 'gulp'
rename         = require 'gulp-rename'

gulp.task 'default', ->

  gulp.src ["./client/**/*", "!node_modules/"], base : "./client/"
    .pipe rename (path, file) ->
      return unless path.extname is '.coffee'

      # console.log "was: ", "#{path.basename}#{path.extname}"
      contents = file.contents.toString()
      n = (/class\s([A-Z]{1}(?:\w|\.)+)/.exec contents)?[0]

      if n
        name = n.replace(/\./, '').replace(/class\s/, '').toLowerCase()
        path.basename = name

      path


    .pipe gulp.dest './client5'
