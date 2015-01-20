class CommentInputWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.type         or= 'new-comment'
    options.cssClass       = KD.utils.curry 'comment-input-widget', options.cssClass
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
    payload  = @getPayload()

    timestamp = Date.now()
    clientRequestId = KD.utils.generateFakeIdentifier timestamp

    @lockSubmit()

    obj = { body, payload, clientRequestId }

    fn = if activity
    then @bound 'update'
    else @bound 'create'

    fn(obj, @bound 'submissionCallback')

    @emit 'SubmitStarted', body, clientRequestId

    KD.utils.defer @bound 'focus'


  create: ({body, clientRequestId}, callback) ->

    { activity } = @getOptions()

    { appManager } = KD.singletons

    appManager.tell 'Activity', 'reply', {activity, body, clientRequestId}, (err, reply) =>

      return KD.showError err  if err

      callback err, reply


  inputFocused: ->

    @emit 'Focused'
    KD.mixpanel 'Comment activity, focus'

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
      , KD.whoami()

    inputWrapper = new KDCustomHTMLView
      cssClass : 'comment-input-wrapper'

    inputWrapper.addSubView @input
    @addSubView inputWrapper
    @addSubView @embedBox
    @addSubView @submitButton

