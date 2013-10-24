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

    avatarOptions  =
      size         :
        width      : 90
        height     : 90
      click        : =>
        pos        =
          top      : @avatar.getBounds().y - 8
          left     : @avatar.getBounds().x - 8
        modal      = new KDModalView
          width    : 400
          fx       : yes
          overlay  : yes
          draggable: yes
          position : pos
        modal.addSubView new AvatarStaticView
          size     :
            width  : 400
            height : 400
        , @memberData

    if KD.whoami().getId() is @memberData.getId()
      avatarOptions.tooltip =
        title    : "<p class='centertext'>please use gravatar.com<br/>to set your avatar</p>"
        placement: "below"

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
    @createBadges()


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

  putPresence: (state) ->
    """
    <div class="presence #{state or 'offline'}">
    #{state or 'offline'}
    </div>
    """

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
    {div{ @putPresence #(onlineStatus)}}
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
        <div class="badges"></div>
        <div class="profilebio">{{> @bio }}</div>
        <div class="personal-skilltags">{{> @skillTagView}}</div>
      </div>
    </section>
    """
