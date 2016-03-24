kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
JView = require '../jview'


# FIXME ~ GG Don't know who is using this. (nfindertreecontroller -og)
module.exports = class DropboxDownloadItemView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'dropbox-download-item'

    super options, data

    fileData = @getData()

    @thumbnail   = new KDCustomHTMLView
      tagName    : 'image'
      attributes :
        src      : fileData.thumbnails['64x64'] or fileData.icon

    @fileName    = new KDCustomHTMLView
      cssClass   : 'file-name'
      partial    : fileData.name

    @fileSize    = new KDCustomHTMLView
      cssClass   : 'file-size'
      partial    : formatBytesToHumanReadable fileData.bytes

    @loader      = new KDLoaderView
      size       :
        width    : 24

    @success     = new KDCustomHTMLView
      cssClass   : 'done'

    @success.hide()

    @on 'FileNeedsToBeDownloaded', (path) ->
      @loader.show()
      kd.getSingleton('vmController').run
        withArgs: "cd #{path} ; wget #{fileData.link}"
        vmName  : @getOptions().nodeView.getData().vmName
      , (err, res) =>
        return kd.warn err  if err
        return kd.warn res.stderr if res.exitStatus > 0

        @loader.hide()
        @success.show()
        @emit 'FileDownloadDone'

  pistachio: ->
    '''
      {{> @thumbnail}}
      <div class="details">
        {{> @fileName}}
        {{> @fileSize}}
      </div>
      <div class="indicators">
        {{> @loader}}
        {{> @success}}
      </div>
    '''
