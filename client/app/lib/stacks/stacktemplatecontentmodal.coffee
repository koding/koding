kd = require 'kd'
timeago = require 'timeago'

Encoder = require 'htmlencode'

StackTemplateEditorView = require 'stack-editor/editor/stacktemplateeditorview'

module.exports = class StackTemplateContentModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-template-content has-markdown'

    options.width    = 800

    options.title    = data.title

    modifiedAt       = data.meta?.modifiedAt
    options.subtitle = "Updated #{timeago new Date modifiedAt}"  if modifiedAt

    options.overlay  = yes
    options.overlayOptions = { cssClass : 'second-overlay' }

    super


  getEditor: ->

    { template: { rawContent } } = @getData()

    return new StackTemplateEditorView
      delegate    : this
      content     : Encoder.htmlDecode rawContent
      contentType : 'yaml'
      readOnly    : yes
      showHelpContent : no


  viewAppended: ->

    @addSubView @tabView = new kd.TabView { hideHandleContainer: yes }

    editorPane = new kd.TabPaneView { view: @getEditor() }
    @tabView.addPane editorPane, yes
