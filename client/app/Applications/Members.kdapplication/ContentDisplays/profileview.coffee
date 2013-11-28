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

    @on "viewAppended", =>
      @overlay = new KDOverlayView
        isRemovable: no
        parent     : "body"

    @on "KDObjectWillBeDestroyed", => @overlay.destroy()

    @avatarData = null

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
        @avatarData = "data:image/png;base64,#{btoa content}"
        @changeHeader "imagedropped"
        @setAvatarImage()

  showPhotoView: ->
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
    @webcamView.on "snap", (data)=> @avatarData = data
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

  setAvatarImage: ->
    @avatar.setAvatar "url(#{@avatarData})"
    @avatar.setSize width: 300, height: 300

  setAvatar: ->
    @setAvatarImage()
    @avatar.show()
    @emit "UsePhoto", @avatarData

  getConfirmView: ->
    new KDButtonView
      cssClass  : "clean-gray confirm avatar-button"
      icon      : yes
      iconOnly  : yes
      iconClass : "okay"
      callback  : => @setAvatar()

  getCancelView: (callback)->
    new KDButtonView
      cssClass  : "clean-gray cancel avatar-button"
      title     : "Cancel"
      callback  : =>
        @changeHeader "actions"
        @resetView()
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


class ProfileView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @memberData    = @getData()
    mainController = KD.getSingleton "mainController"

    if KD.checkFlag 'exempt', @memberData
      if not KD.checkFlag 'super-admin'
        return KD.getSingleton('router').handleRoute "/Activity"

    @editLink = if KD.isMine @memberData
    then new CustomLinkView
      title       : "Edit your profile"
      icon        :
        cssClass  : "edit"
        placement : "right"
      testPath    : "profile-edit-button"
      cssClass    : "edit"
      click       : @bound 'edit'
    else new KDCustomHTMLView

    @saveButton     = new KDButtonView
      testPath      : "profile-save-button"
      cssClass      : "save hidden"
      style         : "cupid-green"
      title         : "Save"
      callback      : @bound 'save'

    @cancelButton   = new CustomLinkView
      title         : "Cancel"
      cssClass      : "cancel hidden"
      click         : @bound 'cancel'

    @firstName      = new KDContentEditableView
      testPath      : "profile-first-name"
      pistachio     : "{{#(profile.firstName) or ''}}"
      cssClass      : "firstName"
      placeholder   : "First name"
      delegate      : this
      validate      :
        rules       :
          required  : yes
          maxLength : 25
        messages    :
          required  : "First name is required"
      , @memberData

    @lastName       = new KDContentEditableView
      testPath      : "profile-last-name"
      pistachio     : "{{#(profile.lastName) or ''}}"
      cssClass      : "lastName"
      placeholder   : "Last name"
      delegate      : this
      validate      :
        rules       :
          maxLength : 25
      , @memberData

    @memberData.locationTags or= []

    @location     = new KDContentEditableView
      testPath    : "profile-location"
      pistachio   : "{{#(locationTags)}}"
      cssClass    : "location"
      placeholder : "Earth"
      default     : "Earth"
      delegate    : this
      , @memberData

    @bio            = new KDContentEditableView
      testPath      : "profile-bio"
      pistachio     : "{{ @utils.applyTextExpansions #(profile.about), yes}}"
      cssClass      : "bio"
      placeholder   : if KD.isMine @memberData then "You haven't entered anything in your bio yet. Why not add something now?" else ""
      textExpansion : yes
      delegate      : this
      click         : (event) => KD.utils.showMoreClickHandler event
    , @memberData

    @firstName.on "NextTabStop", => @lastName.focus()
    @firstName.on "PreviousTabStop", => @bio.focus()
    @lastName.on "NextTabStop", => @location.focus()
    @lastName.on "PreviousTabStop", => @firstName.focus()
    @location.on "NextTabStop", => @bio.focus()
    @location.on "PreviousTabStop", => @lastName.focus()
    @bio.on "NextTabStop", => @firstName.focus()
    @bio.on "PreviousTabStop", => @lastName.focus()

    for input in [@firstName, @lastName, @location, @bio]
      input.on "click", => if not @editingMode and KD.isMine @memberData then @setEditingMode on

    @skillTagView = if KD.isMine @memberData or @memberData.skillTags.length > 0
    then new SkillTagFormView {}, @memberData
    else new KDCustomHTMLView

    @skillTagView.on "AutoCompleteNeedsTagData", (event) =>
      {callback, inputValue, blacklist} = event
      @fetchAutoCompleteDataForTags inputValue, blacklist, callback


    @createBadges()

    avatarOptions  =
      showStatus      : yes
      size            :
        width         : 90
        height        : 90
      click        : =>
        pos        =
          top      : @avatar.getBounds().y - 8
          left     : @avatar.getBounds().x - 8

        if KD.isMine @memberData

          @avatarMenu?.destroy()
          @avatarMenu = new JContextMenu
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
            @avatar.$().css
              backgroundSize: "auto 90px"
            @avatarChange.emit "LoadingStart"
            @uploadAvatar avatarBase64, =>
              @avatarChange.emit "LoadingEnd"


        else
          @modal = new KDModalView
            cssClass : "avatar-container"
            width    : 300
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
    @userHomeLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "user-home-link"
      attributes  :
        href      : "http://#{userDomain}"
        target    : "_blank"
      pistachio   : userDomain
      click       : (event) =>
        KD.utils.stopDOMEvent event unless @memberData.onlineStatus is "online"

    if KD.whoami().getId() is @memberData.getId()
      @followButton = new KDCustomHTMLView
    else
      @followButton = new MemberFollowToggleButton
        style : "kdwhitebtn profilefollowbtn"
      , @memberData

    for route in ['followers', 'following', 'likes']
      @[route] = @getActionLink route, @memberData

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
        partial      : if KD.checkFlag 'exempt', @memberData then 'Unmark Troll' else 'Mark as Troll'
        cssClass     : "troll-switch"
        click        : =>
          if KD.checkFlag 'exempt', @memberData
          then mainController.unmarkUserAsTroll @memberData
          else mainController.markUserAsTroll   @memberData
    else
      @trollSwitch = new KDCustomHTMLView

  viewAppended:->

    super

    @createExternalProfiles()

  uploadAvatar: (avatarData, callback)->
    FSHelper.s3.upload "avatar.png", avatarData, (err, url)=>
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

  setEditingMode: (state) ->
    @editingMode = state
    @emit "EditingModeToggled", state

    if state
      @editLink.hide()
      @saveButton.show()
      @cancelButton.show()
    else
      @editLink.show()
      @saveButton.hide()
      @cancelButton.hide()

  edit:(event)->
    KD.utils.stopDOMEvent event  if event
    @setEditingMode on
    @firstName.focus()

  save: ->
    for input in [@firstName, @lastName]
      unless input.validate() then return

    @setEditingMode off

    @memberData.modify
      "profile.firstName" : @firstName.getValue()
      "profile.lastName"  : @lastName.getValue()
      "profile.about"     : @bio.getValue()
      "locationTags"      : [@location.getValue() || "Earth"]
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

      @utils.defer =>
        @memberData.emit "update"

  cancel:(event)->
    KD.utils.stopDOMEvent event  if event
    @setEditingMode off
    @memberData.emit "update"

  getActionLink: (route) ->
    count    = @memberData.counts[route] or 0
    nickname = @memberData.profile.nickname
    path     = route[0].toUpperCase() + route[1..-1]

    new KDView
      tagName     : 'a'
      attributes  :
        href      : "/#"
      pistachio   : "<cite/><span class=\"data\">#{count}</span> <span>#{path}</span>"
      click       : (event) =>
        event.preventDefault()
        unless @memberData.counts[route] is 0
          KD.getSingleton('router').handleRoute "/#{nickname}/#{path}", {state: @memberData}
    , @memberData

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
    account      = @getData()
    amountOfDays = Math.floor (new Date - new Date(account.meta.createdAt)) / (24*60*60*1000)
    onlineStatus = if account.onlineStatus then 'online' else 'offline'
    """
    <div class="profileleft">
    <span>{{> @avatar}}</span>
    {{> @followButton}}
    {cite{ @putNick #(profile.nickname)}}
    </div>

    {{> @trollSwitch}}

    <section>
      <div class="profileinfo">
        <div class="action-wrapper">{{> @editLink}}{{> @cancelButton}}{{> @saveButton}}</div>
        <h3 class="profilename">{{> @firstName}}{{> @lastName}}</h3>
        <div class="external-profiles"></div>
        <h4 class="profilelocation">{{> @location}}</h4>
        <h5>
          {{> @userHomeLink}}
          <cite>member for #{if amountOfDays < 2 then 'a' else amountOfDays} day#{if amountOfDays > 1 then 's' else ''}.</cite>
        </h5>
        <div class="profilestats">
          <div class="fers">{{> @followers}}</div>
          <div class="fing">{{> @following}}</div>
          <div class="liks">{{> @likes}}</div>
          <div class='contact'>{{> @sendMessageLink}}</div>
        </div>
        <div class="profilebio">{{> @bio }}</div>
        <div class="personal-skilltags">{{> @skillTagView}}</div>
      </div>
    </section>
    """
