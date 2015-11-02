kd = require 'kd'

Encoder = require 'htmlencode'

StackTemplateEditorView = require 'admin/views/stacks/editors/stacktemplateeditorview'

module.exports = class StackTemplateContentModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-template-content has-markdown'

    options.width    = 800

    options.title    = data.title
    options.subtitle = data.modifiedAt

    options.overlay  = yes
    options.overlayOptions = cssClass : 'second-overlay'

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

    @addSubView @tabView = new kd.TabView hideHandleContainer: yes

    editorPane = new kd.TabPaneView view: @getEditor()
    @tabView.addPane editorPane, yes
