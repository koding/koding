kd                  = require 'kd'
KDButtonView        = kd.ButtonView
BaseStackEditorView = require './basestackeditorview'
applyMarkdown       = require 'app/util/applyMarkdown'
contentModal = require 'app/components/contentModal'

module.exports = class MarkdownEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    options.targetContentType ?= 'markdown'

    super options, data


  viewAppended: ->

    super

    @addSubView new KDButtonView
      title    : 'Preview'
      cssClass : 'solid compact light-gray preview-button'
      callback : @bound 'handlePreview'


  handlePreview: ->

    { title } = @getOptions()
    content   = @getContent()

    new contentModal
      width : 600
      overlay : yes
      attributes     : { testpath: 'ReadmePreviewModal' }
      overlayOptions : { cssClass : 'second-overlay' }
      title          : title or 'Readme Preview'
      cssClass       : 'readme-preview has-markdown content-modal'
      content        : applyMarkdown content
