class AvatarChangeHeaderView extends JView

  constructor: (options={}, data)->

    options.tagName  = "article"
    options.cssClass = "avatar-change-header"
    super options, data

  viewAppended: ->
    super
    options = @getOptions()

    if options.title
      @addSubView new KDCustomHTMLView
        tagName: "strong"
        partial: options.title

    if options.buttons?.length > 0
      for button in options.buttons
        @addSubView button

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

class ProfileContentEditableView extends KDContentEditableView
  JView.mixin @prototype

class ProfileView extends JView

  constructor: (options = {}, data) ->

    options.bind   = "mouseenter mouseleave"
    super options, data

    @memberData    = @getData()
    mainController = KD.getSingleton "mainController"

    if @memberData.isExempt
      if not KD.checkFlag 'super-admin'
        return KD.getSingleton('router').handleRoute "/Activity"

    @firstName      = new ProfileContentEditableView
      tagName       : "span"
      testPath      : "profile-first-name"
      pistachio     : "{{#(profile.firstName) or ''}}"
      cssClass      : "firstName"
      placeholder   : "First name"
      delegate      : this
      tabNavigation : yes
      validate      :
        rules       :
          required  : yes
          maxLength : 25
        messages    :
          required  : "First name is required"
      , @memberData

    @lastName       = new ProfileContentEditableView
      tagName       : "span"
      testPath      : "profile-last-name"
      pistachio     : "{{#(profile.lastName) or ''}}"
      cssClass      : "lastName"
      placeholder   : "Last name"
      delegate      : this
      tabNavigation : yes
      validate      :
        rules       :
          maxLength : 25
      , @memberData

    @bio            = new ProfileContentEditableView
      testPath      : "profile-bio"
      pistachio     : "{{#(profile.about) or ''}}"
      cssClass      : "location"
      placeholder   : if KD.isMine @memberData then "Add your location" else ""
      delegate      : this
      tabNavigation : yes
    , @memberData

    save = ->
      @getDelegate().save()
      @setEditingMode off

    focus = (input) ->
      input.setEditingMode on
      input.focus()

    if @memberData.getId() is KD.whoami().getId()
      @firstName.on "NextTabStop",     => focus @lastName
      @firstName.on "PreviousTabStop", => focus @bio
      @lastName.on "NextTabStop",      => focus @bio
      @lastName.on "PreviousTabStop",  => focus @firstName
      @bio.on "NextTabStop",           => focus @firstName
      @bio.on "PreviousTabStop",       => focus @lastName

      @firstName.on "click", -> @setEditingMode on
      @lastName.on "click",  -> @setEditingMode on
      @bio.on "click",       -> @setEditingMode on

      @firstName.on "EnterPressed", save
      @lastName.on "EnterPressed", save
      @bio.on "EnterPressed", save

      @firstName.on "BlurHappened", save
      @lastName.on "BlurHappened", save
      @bio.on "BlurHappened", save

    avatarOptions  =
      size            :
        width         : 143
        height        : 143
      click        : =>
        pos        =
          top      : @avatar.getBounds().y - 8
          left     : @avatar.getBounds().x - 8

        if KD.isMine @memberData

          @avatarMenu?.destroy()
          @avatarMenu = new KDContextMenu
            menuWidth: 312
            cssClass : "avatar-menu dark"
            delegate : @avatar
            x        : @avatar.getX() + 96
            y        : @avatar.getY() - 7
          , customView: @avatarChange = new AvatarChangeView delegate: this, @memberData

          @avatarChange.on "UseGravatar", =>
            @avatarSetGravatar()

          @avatarChange.on "UsePhoto", (dataURI)=>
            [_, avatarBase64] = dataURI.split ","
            @avatar.setAvatar "url(#{dataURI})"
            # i don't know why this was here - SY
            # @avatar.$().css
            #   backgroundSize: "auto 90px"
            @avatarChange.emit "LoadingStart"
            @uploadAvatar avatarBase64, =>
              @avatarChange.emit "LoadingEnd"


        else
          @modal = new KDModalView
            cssClass : "avatar-container"
            width    : 390
            fx       : yes
            overlay  : yes
            draggable: yes
            position : pos

          @modal.addSubView @bigAvatar = new AvatarStaticView
            size     :
              width  : 300
              height : 300
          , @memberData

    if KD.isMine @memberData
      avatarOptions.tooltip =
        # offset      : top: 0, left: -3
        title       : "<p class='centertext'>Click avatar to edit</p>"
        placement   : "below"
        arrow       :
          placement : "top"

    @avatar = new AvatarStaticView avatarOptions, @memberData

    userDomain = @memberData.profile.nickname + "." + KD.config.userSitesDomain
    @userHomeLink = new JCustomHTMLView
      tagName     : "a"
      cssClass    : "user-home-link"
      attributes  :
        href      : "http://#{userDomain}"
        target    : "_blank"
      pistachio   : userDomain
      click       : (event) =>
        KD.utils.stopDOMEvent event unless @memberData.onlineStatus is "online"

    if KD.checkFlag('super-admin') and @memberData.getId() isnt KD.whoami().getId()
    then @trollButton = new TrollButtonView style : 'thin medium red', data
    else @trollButton = new KDCustomHTMLView

    nickname = @memberData.profile.nickname

    @followers = new JView
      tagName     : 'a'
      attributes  :
        href      : ""
      pistachio   : "<span>{{ #(counts.followers) }}</span>Followers"
      click       : (event) =>
        event.preventDefault()
        KD.getSingleton('router').handleRoute "/#{nickname}?filter=followers", {state: @memberData}
    , @memberData

    @following = new JView
      tagName     : 'a'
      attributes  :
        href      : ""
      pistachio   : "<span>{{ #(counts.following) }}</span>Following"
      click       : (event) =>
        event.preventDefault()
        KD.getSingleton('router').handleRoute "/#{nickname}?filter=following", {state: @memberData}
    , @memberData

    @likes = new JView
      tagName     : 'a'
      attributes  :
        href      : ""
      pistachio   : "<span>{{ #(counts.likes) }}</span>Likes"
      click       : (event) =>
        event.preventDefault()
        KD.getSingleton('router').handleRoute "/#{nickname}?filter=likes", {state: @memberData}
    , @memberData

    @sendMessageLink = new KDCustomHTMLView
    unless KD.isMine @memberData
      @sendMessageLink = new MemberMailLink {}, @memberData

    if @sendMessageLink instanceof MemberMailLink
      @sendMessageLink.on "AutoCompleteNeedsMemberData", (pubInst,event) =>
        {callback, inputValue, blacklist} = event
        @fetchAutoCompleteForToField inputValue, blacklist, callback

      @sendMessageLink?.on 'MessageShouldBeSent', ({formOutput, callback}) =>
        @prepareMessage formOutput, callback

    if KD.checkFlag 'super-admin' and not KD.isMine @memberData
      @trollSwitch   = new KDCustomHTMLView
        tagName      : "a"
        partial      : if @memberData.isExempt then 'Unmark Troll' else 'Mark as Troll'
        cssClass     : "troll-switch"
        click        : =>
          if @memberData.isExempt
          then mainController.unmarkUserAsTroll @memberData
          else mainController.markUserAsTroll   @memberData
    else
      @trollSwitch = new KDCustomHTMLView

    # badgeView
    @userBadgesController    = new KDListViewController
      startWithLazyLoader    : no
      view                   : new KDListView
        cssClass             : "badge-list"
        itemClass            : UserBadgeView

    @badgeHeader = new KDCustomHTMLView
      tagName : "h3"

    @memberData.fetchMyBadges (err, badges)=>
      if badges.length > 0
        @badgeHeader.setPartial "Badges"
        @userBadgesController.instantiateListItems badges

    @userBadgesView = @userBadgesController.getView()


    # for admins and moderators, list user badge property counts
    @badgeItemsList = new KDCustomHTMLView
    @thankButton    = new KDCustomHTMLView
    if KD.hasAccess "assign badge"
      @badgeItemsList = new UserPropertyList {}, counts : @memberData.counts
      # show "Thank You" button to admins
      @thankButton = new KDButtonView
        cssClass   : "solid green medium repbutton"
        title      : "+1 rep"
        type       : "submit"
        callback   : =>
          KD.whoami().likeMember @memberData.profile.nickname, (err)=>
            if err
              warn err
            else
              @thankButton.disable()
              @utils.wait 3000, =>
                @thankButton.enable()
      @thankButton.hide()
      @badgeItemsList.hide()

      @on "mouseenter", =>
        @thankButton.show()
        @badgeItemsList.show()

      @on "mouseleave", =>
        @thankButton.hide()
        @badgeItemsList.hide()

  viewAppended:->
    super
    @createExternalProfiles()
    @createBadges()
    KD.utils.defer =>
      return  unless KD.isMine @memberData
      @firstName.setPlaceholder()  unless @firstName.getValue()
      @lastName.setPlaceholder()   unless @lastName.getValue()
      @bio.setPlaceholder()        unless @bio.getValue()

  uploadAvatar: (avatarData, callback)->
    FSHelper.s3.upload "avatar.png", avatarData, "user", "", (err, url)=>
      resized = KD.utils.proxifyUrl url,
        crop: true, width: 300, height: 300

      @memberData.modify "profile.avatar": [url, +new Date()].join("?"), callback

  avatarSetGravatar: (callback)->
    @memberData.modify "profile.avatar": "", callback

  createExternalProfiles:->

    appManager         = KD.getSingleton 'appManager'
    {externalProfiles} = MembersAppController

    for own provider, options of externalProfiles
      @["#{provider}View"]?.destroy()
      @["#{provider}View"] = view = new ExternalProfileView
        provider    : provider
        nicename    : options.nicename
        urlLocation : options.urlLocation

      @addSubView view, '.external-profiles'

  createBadges:->

  save: ->
    for input in [@firstName, @lastName]
      unless input.validate() then return

    @memberData.modify
      "profile.firstName" : @firstName.getValue()
      "profile.lastName"  : @lastName.getValue()
      "profile.about"     : @bio.getValue()
    , (err) =>
      if err
        state = "error"
        message = "There was an error updating your profile"
      else
        state = "success"
        message = "Your profile is updated"

      new KDNotificationView
        title    : message
        type     : "mini"
        cssClass : state
        duration : 2500

  cancel:(event)->
    KD.utils.stopDOMEvent event  if event
    @memberData.emit "update"

  fetchAutoCompleteForToField: (inputValue, blacklist, callback) ->
    KD.remote.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts) ->
      callback accounts

  fetchAutoCompleteDataForTags:(inputValue, blacklist, callback) ->
    KD.remote.api.JTag.byRelevanceForSkills inputValue, {blacklist}, (err, tags) ->
      unless err
        callback? tags
      else
        log "there was an error fetching topics #{err.message}"

  # FIXME: this should be taken to inbox app controller using KD.getSingleton("appManager").tell
  prepareMessage: (formOutput, callback) ->
    {body, subject, recipients} = formOutput
    to = recipients.join ' '

    @sendMessage {to, body, subject}, (err, message) ->
      new KDNotificationView
        title     : if err then "Failure!" else "Success!"
        duration  : 1000
      message.mark 'read'
      callback? err, message

  sendMessage: (messageDetails, callback) ->
    if KD.isGuest()
      return new KDNotificationView
        title: "Sending private message for guests not allowed"

    KD.remote.api.JPrivateMessage.create messageDetails, callback

  putNick: (nick) -> "@#{nick}"

  updateUserHomeLink: ->
    return  unless @userHomeLink

    if @memberData.onlineStatus is "online"
      @userHomeLink.unsetClass "offline"
      @userHomeLink.tooltip?.destroy()
    else
      @userHomeLink.setClass "offline"

      @userHomeLink.setTooltip
        title     : "#{@memberData.profile.nickname}'s VM is offline"
        placement : "right"

  render: ->
    @updateUserHomeLink()
    super

  pistachio: ->
    """
      <main>
        {{> @avatar}}
        <h3 class="full-name">{{> @firstName}} {{> @lastName}}</h3>
        {{> @bio }}
        {{> @trollButton}}
        <div class="profilestats">
          {{> @followers}}
          {{> @following}}
          {{> @likes}}
        </div>
        <div class="user-badges">
          {{> @badgeHeader}}
          {{> @userBadgesView}}
        </div>
        {{> @badgeItemsList}}
        {{> @thankButton}}
      </main>
    """
