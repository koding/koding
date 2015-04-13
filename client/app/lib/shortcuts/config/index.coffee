workspace = require './workspace'
activity  = require './activity'
editor    = require './editor'

workspace = workspace.map (obj) ->
  obj.options = global: true
  return obj

activity = activity.map (obj) ->
  obj.options = global: true
  return obj

editor = editor.map (obj) ->
  obj.options = custom: true
  return obj

exports.workspace = title: 'Workspace', data: workspace
exports.activity  = title: 'Activity', data: activity
exports.editor    = title: 'Editor', data: editor