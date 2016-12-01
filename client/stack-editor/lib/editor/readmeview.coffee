kd = require 'kd'
Encoder = require 'htmlencode'
s3upload             = require 'app/util/s3upload'
MarkdownEditorView = require './markdowneditorview'
ContentModal = require 'app/components/contentModal'

module.exports = class ReadmeView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getData()
    { @canUpdate } = @getOptions()
    
    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else ''

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'
      openFileInput: @bound 'openFileInput'
      setFileInputToUpload: @bound 'setFileInputToUpload'
      setDragClass: @bound 'setDragClass'
      removeDragClass: @bound 'removeDragClass'
      
    @uploadFileInput  = @addSubView new kd.InputView
        type       : 'file'
        cssClass   : 'upload-file-input-hidden'
        change     : @bound 'uploadInputChange'
        attributes :
          accept   : 'image/jpeg,image/jpg,image/jpeg,image/gif,image/png'

  viewAppended: ->

    super

    @editorView.ready =>
      @setReadOnly()  unless @canUpdate
      @listenEditorEvents()


  listenEditorEvents: ->
    
    @on 'FocusToEditor', @editorView.lazyBound 'setFocus', yes


  setReadOnly: ->

    @setClass 'readonly'
    @editorView.aceView.ace.editor.setReadOnly yes
    
    
  setDragClass: ->

    @editorView.aceView.ace.editor.container.classList.add('uploading-files-drag')
    
    
  removeDragClass: ->

    if @editorView.aceView.ace.editor.container.classList.contains('uploading-files-drag')
      @editorView.aceView.ace.editor.container.classList.remove('uploading-files-drag')
    
    
  openFileInput: () ->
    
    @uploadFileInput.domElement[0].click()
    
    
  setFileInputToUpload: (event)->
    
    if event.dataTransfer.files.length > 0
    
      supportedFormats = ['image/jpg','image/jpeg','image/gif','image/png']
      for val in event.dataTransfer.files
      
        fileSize = val.size
        
        if  0 > supportedFormats.indexOf(val.type) or fileSize > 20000000 or fileSize < 2000
          @handleUploadError(val.name)
          return false
          
        that = this
        do () ->
          file = val
          mimeType      = file.type
          reader        = new FileReader
          reader.onload = (event) =>
            dataURL     = event.target.result
            [_, base64] = dataURL.split ','
            that.getFileToUpload
              mimeType : mimeType
              content  : file
      
          reader.readAsDataURL file


  uploadInputChange: ->
    
    file = @uploadFileInput.getElement().files[0]

    return unless file
    
    mimeType      = file.type
    reader        = new FileReader
    reader.onload = (event) =>
      dataURL     = event.target.result
      [_, base64] = dataURL.split ','

      @getFileToUpload
        mimeType : mimeType
        content  : file

    reader.readAsDataURL file


  getFileToUpload: (file, callback) ->
    
    { mimeType, content } = file
    @editorView.aceView.ace.editor.insert("\n[Uploading #{content.name}...]",
    @editorView.aceView.ace.editor.selection.getCursor())
    
    s3upload
      name    : content.name
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>
      console.log err
      whereToReplace = @editorView.aceView.ace.editor.find("[Uploading #{content.name}...]",
        { wrap: true,caseSensitive: false, wholeWord: false,regExp: false,preventScroll: true})
      
      if err
        @editorView.aceView.ace.editor.session.replace(whereToReplace, '')
        @handleUploadError(content.name)
      else
        @editorView.aceView.ace.editor.session.replace(whereToReplace, '![]('+url+')')


  handleUploadError: (fileName) ->
    
    fileErrorContent = "<h6 class='upload-file-title'>Selected file:</h6><div class='upload-file-name'>...#{fileName}</div><div class='upload-file-modal-error'>It seems that file you have selected is wrong file format or the images are broken. Please make sure that you have selected the right file.</div>"
    
    fileError = new kd.CustomHTMLView
      cssClass : 'markdown-content'
      partial : fileErrorContent

    modal = new ContentModal
      width : 650
      overlay : yes
      cssClass : 'has-markdown content-modal'
      overlayOptions : { cssClass : 'second-overlay' }
      title          : 'Something Went Wrong'
      content        : fileError
      buttons      :
        Cancel     :
          title    : 'CANCEL'
          style    : 'cancel button-float-left'
          callback : -> modal.destroy()
        SelectAgain:
          title    : 'SELECT AGAIN AND UPLOAD'
          style    : 'GenericButton button-float-right'
          callback :  =>
            @openFileInput()
            modal.destroy()

