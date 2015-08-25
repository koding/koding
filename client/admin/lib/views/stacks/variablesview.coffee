kd                  = require 'kd'
KDView              = kd.View
KDCustomHTMLView    = kd.CustomHTMLView
VariablesEditorView = require './editors/variableseditorview'


module.exports = class VariablesView extends KDView


  constructor: (options = {}, data) ->

    super options, data

    @addSubView new KDCustomHTMLView
      cssClass  : 'text header'
      partial   : 'Write custom variables here'

    @addSubView @editorView = new VariablesEditorView

