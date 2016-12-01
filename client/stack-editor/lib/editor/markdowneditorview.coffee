kd                  = require 'kd'
KDButtonView        = kd.ButtonView
BaseStackEditorView = require './basestackeditorview'
applyMarkdown       = require 'app/util/applyMarkdown'
ContentModal = require 'app/components/contentModal'
UploadFileButton = require '../components/uploadfilebutton'


module.exports = class MarkdownEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    options.targetContentType ?= 'markdown'
    
    options.bind = 'drag dragstart dragend dragover dragenter dragleave  drop'

    super options, data
    
    @on 'drop', (event) => @listenDropEvent(event)
    @on 'dragenter', (event) => @listenDragEvent(event)
    @on 'dragleave', (event) => @listenLeaveEvent(event)
    
    
  viewAppended: ->

    super
    
    @addSubView new UploadFileButton
      openFileInput : @getOptions().openFileInput
    @addSubView new KDButtonView
      title    : 'Preview'
      cssClass : 'solid compact light-gray preview-button'
      callback : @bound 'handlePreview'
      
  
  listenDragEvent: (event) ->
    
    event.stopPropagation()
    event.preventDefault()
    that = this
    
    setTimeout ->
      that.getOptions().setDragClass()
    , 1
    
  listenLeaveEvent: (event) ->
    
    event.stopPropagation()
    event.preventDefault()
    @getOptions().removeDragClass()
    
    
  listenDropEvent: (event) ->
    
    that = this
    
    setTimeout ->
      that.getOptions().removeDragClass()
    , 17
    
    thisEvent = event
    unless event.dataTransfer
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

