class GroupsUploadView extends JView

  constructor: (options = {}, data) ->

    options.uploaderOptions or= {}

    super options, data

    {cssClass, size, title} = @getOptions().uploaderOptions

    @uploadArea   = new DNDUploader
      uploadToVM  : no
      cssClass    : cssClass or "groups-uploader"
      title       : title    or "Drop your image here!"
      size        : size

    @cancelButton = new KDButtonView
      title       : "Cancel"
      cssClass    : "solid red upload-button cancel"
      callback    : =>
        @emit "UploadCancelled"
        @destroy()

    @saveButton   = new KDButtonView
      title       : "Save"
      cssClass    : "solid green upload-button save"
      disabled    : yes
      callback    : => @uploadToS3()

    @loader       = new KDLoaderView
      cssClass    : "group-upload-loader"
      showLoader  : no
      size        :
        width     : 24

    @uploadArea.on "dropFile", ({origin, content}) =>
      if origin is "external"
        @btoaContent = btoa content
        @uploadArea.updatePartial ""
        @saveButton.enable()
        @btoaContent = btoa content
        @preview "data:image/png;base64,#{@btoaContent}"

  preview: (imageData) ->
    @previewView?.destroy()
    @previewView = new KDCustomHTMLView
      tagName    : "img"
      cssClass   : "group-image-preview"
      attributes :
        src      : imageData

    @uploadArea.addSubView @previewView

  uploadToS3: ->
    #TODO : change the address and name of the logo
    {groupsController} = KD.singletons
    group              = groupsController.getCurrentGroup()
    imageName          = @getOption("fileName") or KD.utils.generatePassword 16, yes

    FSHelper.s3.upload imageName, @btoaContent, (err, url) =>
      if err
        @loader.hide()
        return new KDNotificationView title : "Error while uploading photo."

      proxifyOptions =
        crop   : yes
        width  : 55
        height : 55

      # FIXME - fatihacet - Resized url is not working for now
      resized  = KD.utils.proxifyUrl url, proxifyOptions

      @loader.hide()
      @destroy()
      @emit "FileUploadDone", url

  pistachio: ->
    """
      {{> @uploadArea}}
      {{> @cancelButton}}
      {{> @saveButton}}
      {{> @loader}}
    """
