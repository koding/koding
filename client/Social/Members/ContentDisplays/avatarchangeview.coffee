class AvatarChangeView extends JView

  detectFeatures = ->
    isVideoSupported = KDWebcamView.getUserMediaVendor()
    isDNDSupported   = do ->
      tester = document.createElement('div')
      "draggable" of tester or\
      ("ondragstart" of tester and "ondrop" of tester)
    return {isVideoSupported, isDNDSupported}

  constructor: (options={}, data)->

    options.cssClass = "avatar-change-menu"
    super options, data

    {isVideoSupported, isDNDSupported} = detectFeatures()

    @on "viewAppended", => @overlay = new KDOverlayView

    @on "KDObjectWillBeDestroyed", => @overlay.destroy()

    @avatarData = null
    @avatarPreviewData = null

    @webcamTip = new KDView
      cssClass            : "webcam-tip"
      partial             : "<cite>Please allow Koding to access your camera.</cite>"

    @takePhotoButton = new CustomLinkView
      cssClass            : "take-photo hidden"
      title               : "Take Photo"

    @photoRetakeButton = new KDButtonView
      cssClass            : "clean-gray confirm avatar-button"
      icon                : yes
      iconOnly            : yes
      iconClass           : "cross"
      callback            : =>
        @changeHeader "photo"
        @takePhotoButton.show()
        @webcamView.reset()

    @reuploadButton = new KDButtonView
      cssClass            : "clean-gray confirm avatar-button"
      icon                : yes
      iconOnly            : yes
      iconClass           : "cross"
      callback            : @bound "showUploadView"

    @photoButton = new KDButtonView
      cssClass            : "clean-gray avatar-button"
      title               : "Take Photo"
      disabled            : not isVideoSupported
      callback            : @bound "showPhotoView"

    @uploadButton = new KDButtonView
      cssClass            : "clean-gray avatar-button"
      disabled            : not isDNDSupported
      title               : "Upload Image"
      callback            : @bound "showUploadView"

    @gravatarButton = new KDButtonView
      cssClass            : "clean-gray avatar-button"
      title               : "Use Gravatar"
      callback            : =>
        @avatarPreviewData = @avatar.getGravatarUri()
        @setAvatarPreviewImage()
        @unsetWide()
        @changeHeader "gravatar"

    @gravatarConfirmButton = new KDButtonView
      cssClass            : "clean-gray confirm avatar-button"
      icon                : yes
      iconOnly            : yes
      iconClass           : "okay"
      callback            : =>
        @emit "UseGravatar"
        @changeHeader()

    @avatarHolder = new KDCustomHTMLView
      cssClass: "avatar-holder"
      tagName : "div"

    @avatarHolder.addSubView @avatar = new AvatarStaticView
      size     :
        width  : 300
        height : 300
    , @getData()

    @loader = new KDLoaderView
      size         :
        width      : 15
      loaderOptions:
        color      : "#ffffff"
        shape      : "spiral"

    @cancelPhoto = @getCancelView()

    @headers =
      actions     : new AvatarChangeHeaderView
        buttons   : [@photoButton, @uploadButton, @gravatarButton]

      gravatar    : new AvatarChangeHeaderView
        title     : "Use Gravatar"
        buttons   : [@getCancelView(), @gravatarConfirmButton]

      photo       : new AvatarChangeHeaderView
        title     : "Take Photo"
        buttons   : [@cancelPhoto]

      upload      : new AvatarChangeHeaderView
        title     : "Upload Image"
        buttons   : [@getCancelView()]

      phototaken  : new AvatarChangeHeaderView
        title     : "Take Photo"
        buttons   : [@getCancelView(), @photoRetakeButton, @getConfirmView()]

      imagedropped: new AvatarChangeHeaderView
        title     : "Upload Image"
        buttons   : [@getCancelView(), @reuploadButton, @getConfirmView()]

      loading     : new AvatarChangeHeaderView
        title     : "Uploading and resizing your avatar, please wait..."
        buttons   : [@loader]

    @wrapper = new KDCustomHTMLView
      tagName     : "section"
      cssClass    : "wrapper"

    @wrapper.addSubView view for action, view of @headers

    @on "LoadingEnd",   => @changeHeader()

    @on "LoadingStart", =>
      @changeHeader "loading"
      @unsetWide()

    @once "viewAppended", =>
      @slideDownAvatar()
      @loader.show()

  showUploadView: ->
    @avatarData = @avatar.getAvatar()
    @changeHeader "upload"
    @resetView()
    @unsetWide()
    @avatar.hide()
    @avatarHolder.addSubView @uploaderView = new DNDUploader
      title       : "Drag and drop your avatar here!"
      uploadToVM  : no
      size: height: 280

    @uploaderView.on "dropFile", ({origin, content})=>
      if origin is "external"
        @resetView()
        @avatarPreviewData = "data:image/png;base64,#{btoa content}"
        @changeHeader "imagedropped"
        @setAvatarPreviewImage()

  showPhotoView: ->
    @avatarData = @avatar.getAvatar()
    @changeHeader "photo"
    @resetView()
    @avatar.hide()
    @avatarHolder.addSubView @webcamTip
    @setWide()
    @cancelPhoto.disable()
    @getDelegate().avatarMenu.changeStickyState on

    release = =>
      @cancelPhoto.enable()
      @getDelegate().avatarMenu.changeStickyState off

    @avatarHolder.addSubView @webcamView = new KDWebcamView
      hideControls  : yes
      countdown     : 3
      snapTitle     : "Take Avatar Picture"
      size          :
        width       : 300
      click         : =>
        @webcamView.takePicture()
        @takePhotoButton.hide()
        @changeHeader "phototaken"

    @webcamView.addSubView @takePhotoButton
    @webcamView.on "snap", (data) => @avatarPreviewData = data

    @webcamView.on "allowed", =>
      release()
      @webcamTip.destroy()
      @takePhotoButton.show()

    @webcamView.on "forbidden", =>
      release()
      @webcamTip.updatePartial """
      <cite>
        You disabled the camera for Koding.
        <a href='https://support.google.com/chrome/answer/2693767?hl=en' target='_blank'>How to fix?</a>
      </cite>
      """

  resetView: ->
    @webcamView?.destroy()
    @webcamTip.destroy()
    @uploaderView?.destroy()
    @unsetWide()
    @avatar.show()

  setWide: ->
    @avatarHolder.setClass "wide"
    @avatar.setSize
      width : 300
      height: 225

  unsetWide: ->
    @avatarHolder.unsetClass "wide"
    @avatar.setSize
      width : 300
      height: 300

  setAvatarImage: =>
    @updateAvatarImage @avatarData

  setAvatarPreviewImage : =>
    @avatarData = @avatar.getAvatar()
    @updateAvatarImage @avatarPreviewData

  updateAvatarImage : (imageData) =>
    @avatar.setAvatar "#{imageData}"
    @avatar.setSize width: 300, height: 300

  setAvatar: =>
    @setAvatarImage()
    @avatar.show()
    @emit "UsePhoto", @avatarData

  getConfirmView: ->
    new KDButtonView
      cssClass  : "clean-gray confirm avatar-button"
      icon      : yes
      iconOnly  : yes
      iconClass : "okay"
      callback  : =>
        @avatarData = @avatarPreviewData
        @avatarPreviewData = null
        @setAvatar()

  getCancelView: (callback)->
    new KDButtonView
      cssClass  : "clean-gray cancel avatar-button"
      title     : "Cancel"
      callback  : =>
        @changeHeader "actions"
        @resetView()
        @avatarPreviewData = null
        @setAvatarImage()
        callback?()

  slideDownAvatar: -> @avatarHolder.setClass "opened"
  slideUpAvatar: -> @avatarHolder.unsetClass "opened"

  changeHeader: (viewname="actions")->
    @headers[action]?.hide() for action, view of @headers
    @headers[viewname]?.show()

  pistachio: ->
    """
    <i class="arrow"></i>
    {{> @wrapper}}
    {{> @avatarHolder}}
    """
