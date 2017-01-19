site    = require('./package.json').name
gulp    = require 'gulp'
argv    = require('minimist') process.argv
req     = (module) -> require "./../gulptasks/#{module}"

global.SITE_NAME = site

# CONSTANTS

{
  STYLES_PATH, COFFEE_PATH
  INDEX_PATH, SPRITES_PATH
  BUILD_PATH
} = req 'helper.constants'


# HELPERS

{ watchLogger, log } = req 'helper.logger'


# STYLUS COMPILATION

gulp.task 'styles-only', req 'helper.styles'

gulp.task 'styles', ['sprites'], req 'helper.styles'


# SPRITE GENERATION

gulp.task 'sprites', ['sprites@1x', 'sprites@2x'], ->

gulp.task 'sprites@1x', (req 'task.sprites').bind this, 1

gulp.task 'sprites@2x', ['sprites@1x'], (req 'task.sprites').bind this, 2


# IMAGE MINIFICATION

gulp.task 'imagemin', ['sprites'], req 'task.imagemin'


# COFFEE COMPILATION

gulp.task 'coffee', req 'task.coffee'


# WATCHERS

watchersTasks = [ 'watch-styles', 'watch-coffee', 'watch-sprites' ]

getWatcherTask = (tasks, exporterTask) ->
  tasks.push exporterTask  if argv.exportDir
  return tasks

gulp.task 'watch-sprites', ['sprites'], -> watchLogger 'cyan', gulp.watch SPRITES_PATH, (getWatcherTask ['styles'], 'export-only-sprites')

gulp.task 'watch-styles', ['styles'], -> watchLogger 'cyan', gulp.watch STYLES_PATH, (getWatcherTask ['styles-only'], 'export-only-styles')

gulp.task 'watch-coffee', ['coffee'], -> watchLogger 'cyan', gulp.watch COFFEE_PATH, (getWatcherTask ['coffee'], 'export-only-coffee')

gulp.task 'watchers', watchersTasks

buildTasks = ['libs', 'sprites', 'styles', 'coffee']
buildTasks.push 'imagemin'  if argv.imageMin

# EXPORT

gulp.task 'export-only', req 'task.export'
gulp.task 'export-only-coffee', ['coffee'], req 'task.export'
gulp.task 'export-only-styles', ['styles-only'], req 'task.export'
gulp.task 'export-only-sprites', ['styles'], req 'task.export'

gulp.task 'export', buildTasks, req 'task.export'


# CLEANUP

gulp.task 'clean', req 'task.clean'


# COMBINED TASKS

gulp.task 'libs', req 'task.libs'

gulp.task 'build', buildTasks

gulp.task 'watch', ['build'].concat watchersTasks

defaultTasks = ['watch']
defaultTasks.push 'export'    if argv.exportDir

gulp.task 'default', defaultTasks
