_  = require 'lodash'
kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
ActivityInputWidget = require '../activityinputwidget'
CommentInputView = require './commentinputview'
EmbedBoxWidget = require '../embedboxwidget'
showError = require 'app/util/showError'
trackEvent = require 'app/util/trackEvent'
whoami = require 'app/util/whoami'
generateFakeIdentifier = require 'app/util/generateFakeIdentifier'
AvatarStaticView = require 'app/commonviews/avatarviews/avatarstaticview'


module.exports = class CommentInputWidget extends ActivityInputWidget

  {noop} = kd

  constructor: (options = {}, data) ->

    options.type         or= 'new-comment'
    options.cssClass       = kd.utils.curry 'comment-input-widget', options.cssClass
    options.showAvatar    ?= yes
    options.placeholder    = 'Type your comment'
    options.inputViewClass = CommentInputView

    options.showAvatar    ?= yes

    super options, data


  createSubViews: ->
    { inputViewClass, defaultValue, placeholder } = @getOptions()
    data = @getData()

    @input    = new inputViewClass { defaultValue, placeholder }
    @embedBox = new EmbedBoxWidget delegate: @input, data

    @submitButton = new KDButtonView
      type        : "submit"
      title       : "SEND"
      style       : "solid green mini hidden"
      cssClass    : "submit-button"
      loader      : yes
      disabled    : yes
      attributes  :
        testpath  : "post-activity-button"
      callback    : => @submit @input.getValue()


  initEvents: ->
    @input.on 'Escape', @bound 'reset'
    @input.on 'Enter',  @bound 'submit'
    @input.on 'Tab',    @bound 'focusSubmit'

    @input.on 'focus', @bound 'inputFocused'
    @input.on 'blur',  @bound 'inputBlured'

    @input.on 'keyup', =>
      @showPreview  if @preview

      if @input.getValue().trim()
      then @submitButton.enable()
      else @submitButton.disable()


  setFocus: -> @input.setFocus()


  submit: (value) ->

    return  if @locked
    return @reset yes  unless body = value.trim()

    activity = @getData()
    {app}    = @getOptions()

    embedBoxPayload = @getEmbedBoxPayload()

    payload = _.assign {}, activity?.payload, embedBoxPayload

    timestamp = Date.now()
    clientRequestId = generateFakeIdentifier timestamp

    @lockSubmit()

    obj = { body, payload, clientRequestId }

    fn = if activity
    then @bound 'update'
    else @bound 'create'

    fn(obj, @bound 'submissionCallback')

    @emit 'SubmitStarted', body, clientRequestId

    kd.utils.defer @bound 'focus'


  create: ({body, payload, clientRequestId}, callback) ->

    { activity } = @getOptions()

    { appManager } = kd.singletons

    appManager.tell 'Activity', 'reply', {activity, body, payload, clientRequestId}, (err, reply) =>

      return showError err  if err

      callback err, reply


  inputFocused: ->

    @emit 'Focused'
    trackEvent 'Comment activity, focus'

    @submitButton.show()

    if @input.getValue().trim()
    then @submitButton.enable()
    else @submitButton.disable()


  inputBlured: ->

    return  unless @input.getValue() is ''
    @emit 'Blured'

    @submitButton.disable()
    @submitButton.hide()


  mention: (username) ->

    value = @input.getValue()

    @input.unsetClass 'placeholder'

    @input.setValue \
      if value.indexOf("@#{username}") >= 0 then value
      else if value.length is 0 then "@#{username} "
      else "#{value} @#{username} "

    @setFocus()


  # this is a fix for input view's placeholder
  # flickering when you are already inside of
  # the input box and click to mention. ~Umut
  realSetPlaceholder = CommentInputView::realSetPlaceholder
  disableSetPlaceholder: ->
    realSetPlaceholder    = @input.setPlaceholder
    @input.setPlaceholder = noop


  enableSetPlaceholder: ->
    @input.setPlaceholder = realSetPlaceholder


  viewAppended: ->

    if @getOption 'showAvatar'
      @addSubView new AvatarStaticView
        size    :
          width : 30
          height: 30
      , whoami()

    inputWrapper = new KDCustomHTMLView
      cssClass : 'comment-input-wrapper'

    inputWrapper.addSubView @input
    @addSubView inputWrapper
    @addSubView @embedBox
    inputWrapper.addSubView @submitButton
