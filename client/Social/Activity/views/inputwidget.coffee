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
      attributes  :
        testpath  : "post-activity-button"
      callback    : => @submit @input.getValue()


    @buttonBar    = new KDCustomHTMLView
      cssClass    : "widget-button-bar"

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

    @input.on 'Escape', @bound 'reset'
    @input.on 'Enter',  @bound 'submit'
    @input.on 'Enter', => @input.setBlur()

    @on 'SubmitStarted', => @hidePreview()  if @preview


  submit: (value) ->

    return  if @locked
    return @reset yes  unless body = value.trim()

    activity       = @getData()
    {app, channel} = @getOptions()
    payload        = @getPayload()

    timestamp       = Date.now()
    clientRequestId = KD.utils.generateFakeIdentifier timestamp
    channelId       = channel?.id

    @lockSubmit()

    options = { channelId, body, payload, clientRequestId }

    if activity
    then @update options, @bound 'submissionCallback'
    else @create options, @bound 'submissionCallback'

    @emit 'SubmitStarted', body, clientRequestId


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'SubmitFailed', err, activity.clientRequestId  if activity
      return

    @emit 'SubmitSucceeded', activity

    KD.mixpanel "Status update create, success", { length: activity?.body?.length }


  create: (options, callback) ->

    {appManager} = KD.singletons
    {channel}    = @getOptions()
    {body}       = options

    if channel.typeConstant is 'topic' and not body.match ///\##{channel.name}///
      body += " ##{channel.name} "


    options.body = body

    appManager.tell 'Activity', 'post', options, (err, activity) =>

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

      activity.body = body
      activity.emit 'update'

      callback err, activity

      KD.mixpanel "Status update edit, success"


  reset: (unlock = yes) ->

    @input.empty()
    @input.blur()
    @embedBox.resetEmbedAndHide()

    if unlock then @unlockSubmit()
    else KD.utils.wait 8000, @bound 'unlockSubmit'


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

    data = KD.utils.generateDummyMessage value

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
    @input.setFocus()



  viewAppended: ->

    @addSubView @icon
    # @addSubView @avatar
    @addSubView @input
    @addSubView @embedBox
    @addSubView @buttonBar
    @addSubView @helperView
    @buttonBar.addSubView @submitButton
    @buttonBar.addSubView @previewIcon
    @hide()  unless KD.isLoggedIn()
