workspace = require './defaultshortcuts/workspace'
editor    = require './defaultshortcuts/editor'
editorHidden = require './defaultshortcuts/editorhidden'

workspace = workspace.map (obj) ->
  obj.options = { global: true }
  return obj

editor = editor.map (obj) ->
  obj.options = { custom: true }
  return obj

editorHidden = editorHidden.map (obj) ->
  obj.options = { custom: true, hidden: true }
  return obj

# see: https://github.com/koding/koding/pull/3396#issuecomment-93608293
editor = editor.concat editorHidden

exports.workspace = { title: 'Workspace', data: workspace }
exports.editor    = { title: 'Editor', data: editor }
