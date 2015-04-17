workspace = require './workspace'
activity  = require './activity'
editor    = require './editor'
# see: https://github.com/koding/koding/pull/3396#issuecomment-93608293
editorHidden = require './editordefaults'

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