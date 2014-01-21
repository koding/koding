class UploadImageModalView extends KDModalView

  constructor : (options = {}, data) ->
    options.title         ?= "Upload photo"
    options.uploaderTitle ?= "Drag & drop image here!"
    options.overlay       ?= yes
    options.previewSize   ?= options.imageSize

    super options, data

    @uploaderView    = new DNDUploader
      title          : @getOptions().uploaderTitle
      uploadToVM     : no
      size           : @getOptions().previewSize

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
      size       : @getOptions().previewSize

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
        width        : @getOptions().imageSize.width
        height       : @getOptions().imageSize.height

      resized = KD.utils.proxifyUrl url, proxifyOptions
      group   = KD.singletons.groupsController.getCurrentGroup()

      if @getOptions().imageType is "coverPhoto"
        group.modify "customize.coverPhoto" : [url, +new Date()].join("?"), callback
      else
        group.modify "customize.logo" : [url, +new Date()].join("?"), callback

  uploadLogo:->
    @loaderView.show()
    [_, logoBase64] = @previewData.split ","
    @uploadLogoToS3 logoBase64, =>
      @loaderView.hide()
