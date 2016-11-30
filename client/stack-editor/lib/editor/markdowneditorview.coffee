kd                  = require 'kd'
KDButtonView        = kd.ButtonView
BaseStackEditorView = require './basestackeditorview'
applyMarkdown       = require 'app/util/applyMarkdown'
ContentModal = require 'app/components/contentModal'
UploadFileButton = require '../components/uploadfilebutton'


module.exports = class MarkdownEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    options.targetContentType ?= 'markdown'
    
    options.bind = 'dragover dragleave drop'

    super options, data
    
    @on 'drop', (event) => @listenDropEvent(event)
    @on 'dragover', => @listenDragEvent()
    
    
  viewAppended: ->

    super
    
    @addSubView new UploadFileButton
      openFileInput : @getOptions().openFileInput
    @addSubView new KDButtonView
      title    : 'Preview'
      cssClass : 'solid compact light-gray preview-button'
      callback : @bound 'handlePreview'
      
  
  listenDragEvent: ->
    
    @getOptions().setDragClass()
    
    
  listenDropEvent: (event) ->
    
    @getOptions().removeDragClass()

    thisEvent = event
    if !event.dataTransfer
      thisEvent = event.originalEvent
    @getOptions().setFileInputToUpload(thisEvent)


  handlePreview: ->

    { title } = @getOptions()
    content = @getContent()

    scrollView = new kd.CustomScrollView { cssClass : 'readme-scroll' }

    markdown = applyMarkdown content, { breaks: false }

    scrollView.wrapper.addSubView markdown_content = new kd.CustomHTMLView
      cssClass : 'markdown-content'
      partial : markdown

    new ContentModal
      width : 600
      overlay : yes
      cssClass : 'readme-preview has-markdown content-modal'
      attributes     : { testpath: 'ReadmePreviewModal' }
      overlayOptions : { cssClass : 'second-overlay' }
      title          : title or 'Readme Preview'
      content        : scrollView

