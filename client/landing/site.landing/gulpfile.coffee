gulp    = require 'gulp'
argv    = require('minimist') process.argv
req     = (module, rest...) -> require "./../gulptasks/#{module}", rest...

# CONSTANTS

{ STYLES_PATH, COFFEE_PATH, INDEX_PATH
  SERVER_FILE, SERVER_PATH, BUILD_PATH } = req 'helper.constants'


# HELPERS

{watchLogger, log} = req 'helper.logger'


# BUILD SERVER

gulp.task 'serve', ['build'], -> server = nodemon script: SERVER_FILE


# STYLUS COMPILATION

gulp.task 'styles-only', req 'helper.styles'

gulp.task 'styles', ['sprites'], req 'helper.styles'


# SPRITE GENERATION

gulp.task 'sprites', ['sprites@1x', 'sprites@2x'], ->

gulp.task 'sprites@1x', req 'task.sprites', 1

gulp.task 'sprites@2x', ['sprites@1x'], req 'task.sprites', 2


# COFFEE COMPILATION

gulp.task 'coffee', req 'task.coffee'


# BUILD index.html FILES

gulp.task 'index', req 'task.index'


# BUILD FRAMEWORK FROM NODE MODULE

gulp.task 'build-kd', req 'task.build-kd'


# WATCHERS

watchersArray = [ 'watch-styles', 'watch-coffee', 'watch-index' ]

gulp.task 'watch-styles', -> watchLogger 'cyan', gulp.watch STYLES_PATH, ['styles-only']

gulp.task 'watch-coffee', -> watchLogger 'cyan', gulp.watch COFFEE_PATH, ['coffee']

gulp.task 'watch-index', -> watchLogger 'yellow', gulp.watch INDEX_PATH, ['index']

gulp.task 'watchers', watchersArray


# EXPORT

gulp.task 'export', req 'task.export'


# CLEANUP

gulp.task 'clean', req 'task.clean'


# COMBINED TASKS

gulp.task 'build', ['build-kd', 'sprites', 'styles', 'coffee', 'index']

gulp.task 'watch', ['build'].concat watchersArray

gulp.task 'default', ['watch']
