class ActivityInputWidget extends KDView

  {daisy, dash} = Bongo

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "activity-input-widget", options.cssClass
    super options, data

    options.destroyOnSubmit ?= no
    {defaultValue, placeholder} = options

    inputViewClass = options.inputViewClass ? ActivityInputView

    @input = new inputViewClass {defaultValue, placeholder}
    @input.on "Escape", @bound "reset"
    @input.on "Enter", @bound "submit"

    @input.on "TokenAdded", (type, token) =>
      if token.slug is "bug" and type is "tag"
        @bugNotification.show()
        @setClass "bug-tagged"

    # FIXME we need to hide bug warning in a proper way ~ GG
    @input.on "keyup", =>
      @showPreview() if @preview #Updates preview if it exists

      val = @input.getValue()
      @checkForCommonQuestions val
      if val.indexOf("5051003840118f872e001b91") is -1
        @unsetClass 'bug-tagged'
        @bugNotification.hide()

    @on "ActivitySubmitted", =>
      @unsetClass "bug-tagged"
      @bugNotification.once 'transitionend', =>
        @bugNotification.hide()

    @embedBox = new EmbedBoxWidget delegate: @input, data
    @helperView   = new ActivityInputHelperView

    @submitButton = new KDButtonView
      type        : "submit"
      title       : "SEND"
      cssClass    : "solid green small"
      loader      : yes
      callback    : @bound "submit"

    @icon = new KDCustomHTMLView tagName : 'figure'

    # @avatar = new AvatarView
    #   size      :
    #     width   : 42
    #     height  : 42
    # , KD.whoami()

    @buttonBar = new KDCustomHTMLView
      cssClass : "widget-button-bar"

    @bugNotification = new KDCustomHTMLView
      cssClass : 'bug-notification'
      partial  : '<figure></figure>Posts tagged with <strong>#bug</strong>  will be moved to <a href="/Bugs" target="_blank">Bug Tracker</a>.'

    @bugNotification.hide()
    @bugNotification.bindTransitionEnd()

    @previewIcon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "preview-icon"
      tooltip  :
        title  : "Markdown preview"
      click    : =>
        if not @preview then @showPreview() else @hidePreview()









  submit: (value, timestamp) ->

    return  if @locked
    return @reset yes  unless body = @input.getValue().trim()

    activity = @getData()
    {app}    = @getOptions()

    # fixme for bugs app

    # for token in @input.getTokens()
    #   feedType     = "bug" if token.data?.title?.toLowerCase() is "bug"
    #   {data, type} = token
    #   if type is "tag"
    #     if data instanceof JTag
    #       tags.push id: data.getId()
    #       activity?.tags.push data
    #     else if data.$suggest and data.$suggest not in suggestedTags
    #       suggestedTags.push data.$suggest

    payload = @getPayload()

    @lockSubmit()

    fn = @bound if activity then 'update' else 'create'

    obj = { body, payload }

    if timestamp?
      requestData = KD.utils.generateFakeIdentifier timestamp
      obj.requestData = requestData

    fn obj, @bound 'submissionCallback'

    @emit "ActivitySubmitted"


  submissionCallback: (err, activity) ->

    @reset yes

    return @showError err  if err

    @emit 'MessageSavedSuccessfully', activity

    KD.mixpanel "Status update create, success", { length: activity?.body?.length }


  create: ({body, payload}, callback) ->

    {appManager} = KD.singletons
    {channel}    = @getOptions()

    if channel.typeConstant is 'topic' and not body.match ///\##{channel.name}///
      body += " ##{channel.name} "

    appManager.tell 'Activity', 'post', {body, payload}, (err, activity) =>

      @reset()  unless err

      callback? err, activity

      KD.showError err,
        AccessDenied :
          title      : "You are not allowed to post activities"
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'


  update: ({body, payload}, callback = noop) ->

    {appManager} = KD.singletons
    {channelId}  = @getOptions()
    activity     = @getData()

    return  @reset()  unless activity

    appManager.tell 'Activity', 'edit', {
      id: activity.id
      body
      payload
    }, (err, message) =>

      if err
        options =
          userMessage: "You are not allowed to edit this post."
        return @showError err, options

      @reset()
      callback()

      KD.mixpanel "Status update edit, success"


  reset: (unlock = yes) ->

    @input.setContent ""
    @input.blur()
    @embedBox.resetEmbedAndHide()

    if unlock
    then @unlockSubmit()
    else KD.utils.wait 8000, @bound "unlockSubmit"


  getPayload: ->

    link_url   = @embedBox.url
    link_embed = @embedBox.getDataForSubmit()

    return {link_url, link_embed}  if link_url and link_embed


  showError: (err, options = {}) ->

    KD.showErrorNotification err, options

    @unlockSubmit()


  lockSubmit: ->

    @locked = yes
    @submitButton.disable()
    @submitButton.showLoader()


  unlockSubmit: ->

    @locked = no
    @submitButton.enable()
    @submitButton.hideLoader()


  showPreview: ->

    return unless value = @input.getValue().trim()

    data            =
      on            : -> return this
      watch         : -> return this
      account       : { _id : KD.whoami().getId(), constructorName : "JAccount"}
      body          : value
      typeConstant  : 'post'
      replies       : []
      interactions  :
        like        :
          actorsCount : 0
          actorsPreview : []
      meta          :
        createdAt   : new Date

    @preview?.destroy()
    @addSubView @preview = new ActivityListItemView cssClass: 'preview', data
    @preview.addSubView new KDCustomHTMLView
      cssClass : 'preview-indicator'
      partial  : 'Previewing'
      click    : @bound 'hidePreview'

    @setClass "preview-active"


  hidePreview:->

    @preview.destroy()
    @preview = null
    @unsetClass "preview-active"


  focus: ->

    @input.focus()


  viewAppended: ->

    @addSubView @icon
    # @addSubView @avatar
    @addSubView @input
    @addSubView @embedBox
    @addSubView @buttonBar
    @addSubView @bugNotification
    @addSubView @helperView
    @buttonBar.addSubView @submitButton
    @buttonBar.addSubView @previewIcon
    @hide()  unless KD.isLoggedIn()
