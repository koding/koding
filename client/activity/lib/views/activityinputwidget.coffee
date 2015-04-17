_                       = require 'lodash'
kd                      = require 'kd'
KDButtonView            = kd.ButtonView
KDCustomHTMLView        = kd.CustomHTMLView
KDView                  = kd.View
ActivityInputHelperView = require './activityinputhelperview'
ActivityInputView       = require './activityinputview'
EmbedBoxWidget          = require './embedboxwidget'
globals                 = require 'globals'
trackEvent              = require 'app/util/trackEvent'
showError               = require 'app/util/showError'
generateDummyMessage    = require 'app/util/generateDummyMessage'
generateFakeIdentifier  = require 'app/util/generateFakeIdentifier'
showErrorNotification   = require 'app/util/showErrorNotification'
isLoggedIn              = require 'app/util/isLoggedIn'

module.exports = class ActivityInputWidget extends KDView

  {noop} = kd

  constructor: (options = {}, data) ->
    options.cssClass = kd.utils.curry "activity-input-widget", options.cssClass
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
      click      : => if not @preview then @showPreview() else @hidePreview()


  initEvents: ->

    @input.on 'Escape',   @bound 'reset'
    @input.on 'Enter',    @bound 'submit'
    @input.on 'Tab',      @bound 'focusSubmit'
    @input.on 'keypress', @bound 'updatePreview'

    @on 'SubmitStarted', => @hidePreview()  if @preview


  focusSubmit: ->

    @submitButton.focus()


  submit: (value) ->

    return  if @locked
    return @reset yes  unless body = value.trim()

    activity        = @getData()
    {app, channel}  = @getOptions()
    embedBoxPayload = @getEmbedBoxPayload()

    payload = _.assign {}, activity?.payload, embedBoxPayload

    timestamp       = Date.now()
    clientRequestId = generateFakeIdentifier timestamp
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

    trackEvent "Status update create, success", { length: activity?.body?.length }


  create: (options, callback) ->

    {appManager} = kd.singletons
    {channel}    = @getOptions()
    {body}       = options

    if channel.typeConstant is 'topic' and not body.match ///\##{channel.name}///
      body += " ##{channel.name} "


    options.body = body

    appManager.tell 'Activity', 'post', options, (err, activity) =>

      callback? err, activity

      showError err,
        AccessDenied :
          title      : 'You are not allowed to post activities'
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'


  update: (options = {}, callback = noop) ->

    {body, payload} = options
    {appManager}    = kd.singletons
    {channelId}     = @getOptions()
    activity        = @getData()

    return  @reset()  unless activity

    appManager.tell 'Activity', 'edit', { id: activity.id, body, payload }, (err, message) =>

      if err
        return @showError err, userMessage : 'You are not allowed to edit this post.'

      activity.body = body
      activity.link = payload

      activity.emit 'update'

      callback err, activity

      trackEvent 'Status update edit, success'


  reset: (unlock = yes) ->

    @input.emit 'reset'

    @input.empty()
    @input.setBlur()

    if unlock then @unlockSubmit()
    else kd.utils.wait 8000, @bound 'unlockSubmit'


  getEmbedBoxPayload: -> return @embedBox.getData()


  showError: (err, options = {}) ->

    showErrorNotification err, options

    @unlockSubmit()


  lockSubmit: ->

    @locked = yes
    @submitButton.disable()
    @submitButton.showLoader()


  unlockSubmit: ->

    @locked = no
    @submitButton.enable()
    @submitButton.hideLoader()


  updatePreview: ->
    return unless value = @input.getValue().trim()
    return unless @preview

    data = generateDummyMessage value

    @preview.setData data
    @preview.render()


  showPreview: ->

    return unless value = @input.getValue().trim()

    data = generateDummyMessage value

    @preview?.destroy()
    ActivityListItemView = require './activitylistitemview'
    @addSubView @preview = new ActivityListItemView
      cssClass: 'preview'
      showMore: no,
      data

    @preview.addSubView new KDCustomHTMLView
      cssClass : 'preview-indicator'
      partial  : 'Previewing'
      click    : @bound 'hidePreview'

    @setClass "preview-active"


  hidePreview:->

    @preview.destroy()
    @preview = null
    @unsetClass "preview-active"


  focus: -> @input.setFocus()


  viewAppended: ->

    @addSubView @icon
    @addSubView @input
    @addSubView @embedBox
    @addSubView @buttonBar
    @addSubView @helperView
    @buttonBar.addSubView @submitButton
    @buttonBar.addSubView @previewIcon
    @hide()  unless isLoggedIn()


