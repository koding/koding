kd = require 'kd'
Encoder = require 'htmlencode'
s3upload             = require 'app/util/s3upload'
MarkdownEditorView = require './markdowneditorview'
ContentModal = require 'app/components/contentModal'
UploadFileButton = require '../components/uploadfilebutton'

module.exports = class ReadmeView extends kd.View

  constructor: (options = {}, data) ->

    options.bind = 'drag dragstart dragend dragover dragenter dragleave  drop'

    super options, data

    @on 'drop', (event)=> @listenDropEvent(event)
    @on 'dragenter', => kd.utils.defer => @getOptions().setDragClass()
    @on 'dragleave', => @editorView.getAce().unsetClass 'files-being-dragged'
    @on 'drop', => @editorView.getAce().unsetClass 'files-being-dragged'

    { stackTemplate } = @getData()
    { @canUpdate } = @getOptions()

    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else ''

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'
      openFileInputCallback: @bound 'openFileInput'
      setFileInputToUpload: @bound 'setFileInputToUpload'

    @uploadFileInput  = @addSubView new kd.InputView
        type       : 'file'
        cssClass   : 'hidden'
        change     : @bound 'uploadInputChange'
        attributes :
          accept   : 'image/jpeg,image/jpg,image/jpeg,image/gif,image/png'

  viewAppended: ->

    super

    @editorView.ready =>
      @setReadOnly()  unless @canUpdate
      @listenEditorEvents()

    @addSubView new UploadFileButton
      callback : @getOptions().openFileInputCallback


  handleDragender: ->
    @editorView.getAce().setClass 'files-being-dragged'


  listenEditorEvents: ->

    @on 'FocusToEditor', @editorView.lazyBound 'setFocus', yes


  listenDropEvent: (event) ->

    @editorView.getAce().setClass 'files-being-dragged'

    thisEvent = event
    unless event.dataTransfer
      thisEvent = event.originalEvent
    @getOptions().setFileInputToUpload(thisEvent)


  setReadOnly: ->

    @setClass 'readonly'
    @editorView.aceView.ace.editor.setReadOnly yes


  openFileInput: () ->

    @uploadFileInput.domElement[0].click()


  setFileInputToUpload: (event)->

    return unless event.dataTransfer.files.length

      supportedFormats = ['image/jpg','image/jpeg','image/gif','image/png']
      for val in event.dataTransfer.files

        fileSize = val.size

        if val.type in supportedFormats or fileSize > 20000000 or fileSize < 2000
          @handleUploadError val.name
          return false

        do =>
          file = val
          mimeType      = file.type
          reader        = new FileReader
          reader.onload = (event) =>
            dataURL     = event.target.result
            [_, base64] = dataURL.split ','
            @getFileToUpload
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
    editor = @editorView.getAce()
    editor.insert("\n[Uploading #{content.name}...]",
      editor.getCursor())

    s3upload
      name    : content.name
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>
      console.log err
      whereToReplace = editor.find("[Uploading #{content.name}...]",
        { wrap: true, caseSensitive: false, wholeWord: false, regExp: false, preventScroll: true})

      if err
        editor.session.replace(whereToReplace, '')
        @handleUploadError(content.name)
      else
        editor.getSession().replace(whereToReplace, '![]('+url+')')


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
