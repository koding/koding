_                       = require 'lodash'
kd                      = require 'kd'
KDButtonView            = kd.ButtonView
KDCustomHTMLView        = kd.CustomHTMLView
KDView                  = kd.View
ActivityInputHelperView = require './activityinputhelperview'
ActivityInputView       = require './activityinputview'
EmbedBoxWidget          = require './embedboxwidget'
globals                 = require 'globals'
showError               = require 'app/util/showError'
generateDummyMessage    = require 'app/util/generateDummyMessage'
generateFakeIdentifier  = require 'app/util/generateFakeIdentifier'
isLoggedIn              = require 'app/util/isLoggedIn'
SuggestionMenuView      = require 'activity/components/suggestionmenu/view'
ActivityFlux            = require 'activity/flux'

module.exports = class ActivityInputWidget extends KDView

  {noop}     = kd

  constructor: (options = {}, data) ->
    options.cssClass = kd.utils.curry "activity-input-widget", options.cssClass
    options.destroyOnSubmit     ?= no
    options.inputViewClass      ?= ActivityInputView
    options.isSuggestionEnabled ?= no

    super options, data

    @createSubViews()
    @initEvents()


  createSubViews: ->

    {defaultValue, placeholder, inputViewClass, isSuggestionEnabled} = @getOptions()
    data = @getData()

    @input        = new inputViewClass {defaultValue, placeholder}
    @suggestions  = new SuggestionMenuView()  if isSuggestionEnabled
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

    return  unless @getOptions().isSuggestionEnabled

    @input.on 'keydown',   kd.utils.debounce 300, @bound 'updateSuggestionsQuery'
    @input.on 'focus',     @bound 'makeSuggestionsVisible'
    @input.on 'DownArrow', @bound 'handleDownArrow'
    @input.on 'UpArrow',   @bound 'handleUpArrow'
    @input.on 'Esc',       @bound 'handleEsc'
    @input.on 'RawEnter',  @bound 'handleRawEnter'
    @suggestions.on 'SubmitRequested', @bound 'handleSuggestionsSubmit'


  focusSubmit: ->

    @submitButton.focus()


  handleSuggestionsSubmit: ->

    return  unless @suggestions

    @suggestions.setVisibility no
    @submitButton.click()


  handleDownArrow: (event) ->

    return  unless @suggestions and @suggestions.isVisible

    kd.utils.stopDOMEvent event
    @suggestions.moveToNextIndex()


  handleUpArrow: (event) ->

    return  unless @suggestions and @suggestions.isVisible

    kd.utils.stopDOMEvent event
    @suggestions.moveToPrevIndex()


  handleEsc: (event) ->

    return  unless @suggestions and @suggestions.isVisible

    kd.utils.stopDOMEvent event
    @suggestions.disable()


  handleRawEnter: (event) ->

    return  unless @suggestions and @suggestions.isVisible

    kd.utils.stopDOMEvent event
    @suggestions.confirmSelectedItem()


  submit: (value) ->

    return  if @locked
    return @reset yes  unless body = value.trim()

    @lockSubmit()

    timestamp       = Date.now()
    clientRequestId = generateFakeIdentifier timestamp

    if @embedBox.isFetching
      @embedBox.once 'EmbedFetched', @lazyBound 'submitOnEmbedBoxReady', clientRequestId, body
    else
      @submitOnEmbedBoxReady clientRequestId, body

    @emit 'SubmitStarted', body, clientRequestId


  submitOnEmbedBoxReady: (clientRequestId, body) ->

    activity        = @getData()
    {app, channel}  = @getOptions()
    embedBoxPayload = @getEmbedBoxPayload()

    payload = _.assign {}, activity?.payload, embedBoxPayload

    channelId       = channel?.id

    options = { channelId, body, payload, clientRequestId }

    if activity
    then @update options, @bound 'submissionCallback'
    else @create options, @bound 'submissionCallback'

    @embedBox.close()


  submissionCallback: (err, activity) ->

    if err
      @showError err
      @emit 'SubmitFailed', err, activity.clientRequestId  if activity
      return

    @emit 'SubmitSucceeded', activity


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
        err.message = 'You are not allowed to edit this post.'  unless err.message
        return @showError err

      activity.body    = body
      activity.payload = message.payload
      activity.link    = payload

      activity.emit 'update'

      callback err, activity


  reset: (unlock = yes) ->

    @input.emit 'reset'

    @input.empty()
    @input.setBlur()

    if unlock then @unlockSubmit()
    else kd.utils.wait 8000, @bound 'unlockSubmit'

    @suggestions.reset()  if @getOptions().isSuggestionEnabled


  getEmbedBoxPayload: -> return @embedBox.getData()


  showError: (err) ->

    showError err
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
    @addSubView @suggestions  if @suggestions?
    @addSubView @embedBox
    @addSubView @buttonBar
    @addSubView @helperView
    @buttonBar.addSubView @submitButton
    @buttonBar.addSubView @previewIcon
    @hide()  unless isLoggedIn()


  makeSuggestionsVisible: ->

    return  unless @suggestions
    @suggestions.setVisibility yes


  updateSuggestionsQuery: ->

    return  unless @suggestions

    query = @input.getValue()
    { reactor } = kd.singletons
    { getters } = ActivityFlux

    lastQuery = reactor.evaluate getters.currentSuggestionsQuery
    @suggestions.setQuery query  if query isnt lastQuery
