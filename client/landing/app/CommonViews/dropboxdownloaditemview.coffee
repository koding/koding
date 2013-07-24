class DropboxDownloadItemView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "dropbox-download-item"

    super options, data

    fileData = @getData()

    @thumbnail   = new KDCustomHTMLView
      tagName    : "image"
      attributes :
        src      : fileData.thumbnails["64x64"] or fileData.icon

    @fileName    = new KDCustomHTMLView
      tagName    : "div"
      cssClass   : "file-name"
      partial    : fileData.name

    @fileSize    = new KDCustomHTMLView
      tagName    : "div"
      cssClass   : "file-size"
      partial    : KD.utils.formatBytesToHumanReadable fileData.bytes

    @loader      = new KDLoaderView
      size       :
        width    : 24
        height   : 24

    @success     = new KDCustomHTMLView
      cssClass   : "done"

    @success.hide()

    @on "FileNeedsToBeDownloadad", (path) ->
      @loader.show()
      KD.getSingleton("kiteController").run "cd #{path} ; wget #{fileData.link}", (err, res) =>
        return  warn err if err
        @loader.hide()
        @success.show()
        @emit "FileDownloadDone"

  pistachio: ->
    """
      {{> @thumbnail}}
      <div class="details">
        {{> @fileName}}
        {{> @fileSize}}
      </div>
      <div class="indicators">
        {{> @loader}}
        {{> @success}}
      </div>
    """