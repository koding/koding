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


    @trollButton    = new KDCustomHTMLView
    @metaInfoButton = new KDCustomHTMLView

    if KD.checkFlag('super-admin')

      unless KD.isMine @memberData

        @trollButton = new TrollButtonView
          style : 'solid medium red'
        , data

      @metaInfoButton = new MetaInfoButtonView
        style : 'solid medium green'
      , data


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
        title: "Sending chat message for guests not allowed"

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
        {{> @metaInfoButton}}
        <div class="profilestats">
          {{> @followers}}
          {{> @following}}
          {{> @likes}}
        </div>
      </main>
    """
