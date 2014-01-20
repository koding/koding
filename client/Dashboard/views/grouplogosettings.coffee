class GroupLogoSettings extends KDView
  constructor:(options = {}, data)->
    super options, data

    @groupLogoView = new KDCustomHTMLView
      tagName     : 'img'
      size        :
          width   : 55
          height  : 55
      attributes  :
        src       : ""
      click       : (event) =>
        @showLogoUploadView()

  showLogoUploadView : ->
    logoHolder       = new KDModalView
      title          : "Change Group Logo"
      overlay        : yes

    @uploaderView    = new DNDUploader
      title          : "Drag & drop logo here!"
      uploadToVM     : no
      size           :
        height       : 220
        width        : 220

    uploadButton     = new KDButtonView
      title          : "Upload"
      cssClass       : "solid green"
      callback       : =>
        @uploadLogo()

    @logoLoaderView  = new KDLoaderView
      showLoader     : no
      size           :
        width        : 32

    logoHolder.addSubView @uploaderView
    logoHolder.addSubView uploadButton
    logoHolder.addSubView @logoLoaderView

    @uploaderView.on "dropFile", ({origin, content})=>
      if origin is "external"
        @previewData = "data:image/png;base64,#{btoa content}"
        @updateLogoImage()

  updateLogoImage : =>
    @logoPreview?.destroy()
    @logoPreview = new KDCustomHTMLView
      tagName    : "img"
      attributes :
        src      : @previewData
      size       :
        height   : 220
        width    : 220

    @uploaderView.addSubView @logoPreview

  uploadLogoToS3: (avatarData, callback)->
    #TODO : change the address and name of the logo
    FSHelper.s3.upload "grouplogo-test1.png", avatarData, (err, url)=>
      resized = KD.utils.proxifyUrl url,
        crop: true, width: 55, height: 55
      #TODO : update with JGroup
      callback err, url
      # @memberData.modify "profile.avatar": [url, +new Date()].join("?"), callback

  uploadLogo:->
    @logoLoaderView.show()
    [_, logoBase64] = @previewData.split ","
    @uploadLogoToS3 logoBase64, =>
      @logoLoaderView.hide()

  pistachio:->
    """
    {{> @groupLogoView}}
    """

  viewAppended:JView::viewAppended
