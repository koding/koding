kd                  = require 'kd'
KDModalView         = kd.ModalView
KDButtonView        = kd.ButtonView

BaseStackEditorView = require './basestackeditorview'
applyMarkdown       = require 'app/util/applyMarkdown'


module.exports = class MarkdownEditorView extends BaseStackEditorView

  viewAppended: ->
    super

    @addSubView new KDButtonView
      title    : 'Preview'
      cssClass : 'solid compact light-gray preview-button'
      callback : @bound 'handlePreview'


  handlePreview: ->

    { title } = @getOptions()
    content   = @getContent()

    new kd.ModalView
      title          : title or 'Readme Preview'
      cssClass       : 'has-markdown content-modal'
      height         : 500
      overlay        : yes
      overlayOptions : cssClass : 'second-overlay'
      content        : applyMarkdown content

