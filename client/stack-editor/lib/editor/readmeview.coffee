kd = require 'kd'
Encoder = require 'htmlencode'
s3upload             = require 'app/util/s3upload'
MarkdownEditorView = require './markdowneditorview'
ContentModal = require 'app/components/contentModal'

module.exports = class ReadmeView extends kd.View

  constructor: (options = {}, data) ->

    options.bind = 'drag dragstart dragend dragover dragenter dragleave  drop'

    super options, data

    @on 'drop', (event) => @listenDropEvent(event)
    @on 'dragenter', => kd.utils.defer => @editorView.getAce().setClass 'files-being-dragged'
    @on 'dragleave', => @editorView.getAce().unsetClass 'files-being-dragged'
    @on 'drop', =>  kd.utils.defer => @editorView.getAce().unsetClass 'files-being-dragged'


    { stackTemplate } = @getData()
    { @canUpdate } = @getOptions()

    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else ''

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'

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


  handleDragender: ->
    @editorView.getAce().setClass 'files-being-dragged'


  listenEditorEvents: ->

    @on 'FocusToEditor', @editorView.lazyBound 'setFocus', yes


  listenDropEvent: (event) ->

    thisEvent = event
    unless event.dataTransfer
      thisEvent = event.originalEvent
    @setFileInputToUpload(thisEvent)


  setReadOnly: ->

    @setClass 'readonly'
    @editorView.aceView.ace.editor.setReadOnly yes


  openFileInput: ->

    @uploadFileInput.domElement[0].click()


  setFileInputToUpload: (event) ->

    supportedFormats = ['image/jpg', 'image/jpeg', 'image/gif', 'image/png']

    for val in event.dataTransfer.files

      fileSize = val.size
      if not val.type in supportedFormats or fileSize > 20000000 or fileSize < 2000
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
    editorView = @editorView.getAce()
    editorView.editor.insert("\n[Uploading #{content.name}...]",
      editorView.getCursor())

    s3upload
      name    : content.name
      content : content
      mimeType: mimeType
      timeout : 30000
    , (err, url) =>

      whereToReplace = editorView.editor.find(
        "[Uploading #{content.name}...]", {
          wrap: yes
          caseSensitive: no
          wholeWord: no
          regExp: no
          preventScroll: yes
        }
      )

      if err
        editorView.editor.replace('', whereToReplace)
        @handleUploadError(content.name)
      else
        editorView.editor.replace("![](#{url})", whereToReplace)


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
          style    : 'cancel fl'
          callback : -> modal.destroy()
        SelectAgain:
          title    : 'SELECT AGAIN AND UPLOAD'
          style    : 'GenericButton fr'
          callback :  =>
            @openFileInput()
            modal.destroy()
