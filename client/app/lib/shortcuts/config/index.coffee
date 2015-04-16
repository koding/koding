workspace = require './workspace'
activity  = require './activity'
editor    = require './editor'
editorHidden = require './editor-hidden-defaults'

workspace = workspace.map (obj) ->
  obj.options = global: true
  return obj

activity = activity.map (obj) ->
  obj.options = global: true
  return obj

editor = editor.map (obj) ->
  obj.options = custom: true
  return obj

editorHidden = editorHidden.map (obj) ->
  obj.options = custom: true, hidden: true
  return obj

editor = editor.concat editorHidden

exports.workspace = title: 'Workspace', data: workspace
exports.activity  = title: 'Activity Feed', data: activity
exports.editor    = title: 'Editor', data: editor