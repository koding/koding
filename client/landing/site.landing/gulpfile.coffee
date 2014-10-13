site    = require('./package.json').name
gulp    = require 'gulp'
argv    = require('minimist') process.argv
req     = (module) -> require "./../gulptasks/#{module}"

GLOBAL.SITE_NAME = site

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

gulp.task 'sprites@1x', (req 'task.sprites').bind this, 1

gulp.task 'sprites@2x', ['sprites@1x'], (req 'task.sprites').bind this, 2


# COFFEE COMPILATION

gulp.task 'coffee', req 'task.coffee'


# BUILD FRAMEWORK FROM NODE MODULE

gulp.task 'build-kd', req 'task.build-kd'


# WATCHERS

watchersTasks = [ 'watch-styles', 'watch-coffee' ]

getWatcherTask = (tasks, exporterTask) ->
  tasks.push exporterTask  if argv.exportDir
  return tasks

gulp.task 'watch-styles', ['styles'], -> watchLogger 'cyan', gulp.watch STYLES_PATH, (getWatcherTask ['styles-only'], 'export-only-styles')

gulp.task 'watch-coffee', ['coffee'], -> watchLogger 'cyan', gulp.watch COFFEE_PATH, (getWatcherTask ['coffee'], 'export-only-coffee')

gulp.task 'watchers', watchersTasks

buildTasks = ['build-kd', 'libs', 'sprites', 'styles', 'coffee']

# EXPORT

gulp.task 'export-only', req 'task.export'
gulp.task 'export-only-coffee', ['coffee'], req 'task.export'
gulp.task 'export-only-styles', ['styles-only'], req 'task.export'

gulp.task 'export', buildTasks, req 'task.export'


# CLEANUP

gulp.task 'clean', req 'task.clean'


# COMBINED TASKS

log 'green', buildTasks

gulp.task 'libs', req 'task.libs'

gulp.task 'build', buildTasks

gulp.task 'watch', ['build'].concat watchersTasks

defaultTasks = ['watch']
defaultTasks.push 'export'  if argv.exportDir

gulp.task 'default', defaultTasks
