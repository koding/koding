class UploadImageModalView extends KDModalView

  constructor : (options = {}, data) ->
    options.title         ?= "Upload photo"
    options.uploaderTitle ?= "Drag & drop image here!"
    options.overlay       ?= yes
    options.preview       ?= options.image

    super options, data

    @uploaderView    = new DNDUploader
      title          : @getOptions().uploaderTitle
      uploadToVM     : no
      size           : @getOptions().preview.size

    uploadButton     = new KDButtonView
      title          : "Upload"
      cssClass       : "solid green"
      callback       : =>
        @uploadLogo()

    @loaderView  = new KDLoaderView
      showLoader     : no
      size           :
        width        : 32

    @uploaderView.on "dropFile", ({origin, content})=>
      if origin is "external"
        @previewData = "data:image/png;base64,#{btoa content}"
        @updateLogoImage()

    @addSubView @uploaderView
    @addSubView uploadButton
    @addSubView @loaderView

  updateLogoImage : =>
    @logoPreview?.destroy()
    @logoPreview = new KDCustomHTMLView
      tagName    : "img"
      attributes :
        src      : @previewData
      size       : @getOptions().preview.size

    @uploaderView.addSubView @logoPreview

  uploadLogoToS3: (avatarData, callback)->
    #TODO : change the address and name of the logo
    FSHelper.s3.upload "grouplogo-test1.png", avatarData, (err, url)=>
      if err
        new KDNotificationView title : "Error while uploading photo."
        @loaderView.hide()
        return

      proxifyOptions =
        crop         : true
        width        : @getOptions().image.size.width
        height       : @getOptions().image.size.height

      resized = KD.utils.proxifyUrl url, proxifyOptions
      group   = KD.singletons.groupsController.getCurrentGroup()

      if @getOptions().image.type is "coverPhoto"
        group.modify "customize.coverPhoto" : "#{url}?#{Date.now()}",  callback
      else
        group.modify "customize.logo" : "#{url}?#{Date.now()}", callback

  uploadLogo:->
    @loaderView.show()
    [_, logoBase64] = @previewData.split ","
    @uploadLogoToS3 logoBase64, =>
      @loaderView.hide()
