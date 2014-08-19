class ActivityInputWidget extends KDView

  {daisy, dash} = Bongo

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "activity-input-widget", options.cssClass
    options.destroyOnSubmit ?= no
    options.inputViewClass  ?= ActivityInputView

    super options, data


    @createSubViews()
    @initEvents()


  createSubViews: ->

    {defaultValue, placeholder, inputViewClass} = @getOptions()
    data = @getData()

    @input        = new inputViewClass {defaultValue, placeholder}
    @helperView   = new ActivityInputHelperView
    @embedBox     = new EmbedBoxWidget delegate: @input, data
    @icon         = new KDCustomHTMLView tagName : 'figure'

    @submitButton = new KDButtonView
      type        : "submit"
      title       : "SEND"
      cssClass    : "solid green small"
      loader      : yes
      callback    : => @submit @input.getValue()

    @buttonBar    = new KDCustomHTMLView
      cssClass    : "widget-button-bar"

    @bugNotification = new KDCustomHTMLView
      cssClass : 'bug-notification hidden'
      partial  : '<figure></figure>Posts tagged
        with <strong>#bug</strong> will be
        moved to <a href="/Bugs" target="_blank">
        Bug Tracker</a>.'

    @bugNotification.bindTransitionEnd()

    @previewIcon = new KDCustomHTMLView
      tagName    : "span"
      cssClass   : "preview-icon"
      tooltip    :
        title    : "Markdown preview"
      click      : =>
        if not @preview
        then @showPreview()
        else @hidePreview()


  initEvents: ->

    @input.on "Escape", @bound "reset"
    @input.on "Enter",  @bound "submit"

    @input.on "TokenAdded", (type, token) =>
      if token.slug is "bug" and type is "tag"
        @bugNotification.show()
        @setClass "bug-tagged"

    # FIXME we need to hide bug warning in a proper way ~ GG
    @input.on "keyup", =>
      @showPreview() if @preview #Updates preview if it exists

      val = @input.getValue()
      @helperView?.checkForCommonQuestions val
      if val.indexOf("5051003840118f872e001b91") is -1
        @unsetClass 'bug-tagged'
        @bugNotification.hide()

    @on "SubmitStarted", =>
      @unsetClass "bug-tagged"
      @bugNotification.once 'transitionend', =>
        @bugNotification.hide()


  submit: (value) ->

    return  if @locked
    return @reset yes  unless body = value.trim()

    activity = @getData()
    {app}    = @getOptions()
    payload  = @getPayload()

    timestamp = Date.now()
    clientRequestId = KD.utils.generateFakeIdentifier timestamp

    @lockSubmit()

    obj = { body, payload, clientRequestId }

    fn = if activity
    then @bound 'update'
    else @bound 'create'

    fn(obj, @bound 'submissionCallback')

    @emit 'SubmitStarted', value, clientRequestId


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'SubmitFailed', err

    @emit 'SubmitSucceeded', activity

    KD.mixpanel "Status update create, success", { length: activity?.body?.length }


  create: ({body, payload, clientRequestId}, callback) ->

    {appManager} = KD.singletons
    {channel}    = @getOptions()

    if channel.typeConstant is 'topic' and not body.match ///\##{channel.name}///
      body += " ##{channel.name} "

    appManager.tell 'Activity', 'post', {body, payload, clientRequestId}, (err, activity) =>

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
