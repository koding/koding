class CommentInputWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.type         or= 'new-comment'
    options.cssClass       = KD.utils.curry 'comment-input-widget', options.cssClass
    options.showAvatar    ?= yes
    options.placeholder    = 'Type your comment and hit enter...'
    options.inputViewClass = CommentInputView

    options.showAvatar    ?= yes

    super options, data


  createSubViews: ->
    { inputViewClass, defaultValue, placeholder } = @getOptions()
    data = @getData()

    @input    = new inputViewClass { defaultValue, placeholder }
    @embedBox = new EmbedBoxWidget delegate: @input, data


  initEvents: ->
    @input.on 'Escape', @bound 'reset'
    @input.on 'Enter',  @bound 'submit'

    @input.on 'focus', @bound 'inputFocused'
    @input.on 'blur',  @bound 'inputBlured'

    @input.on 'keyup', =>
      @showPreview  if @preview


  lockSubmit: -> @locked = yes


  unlockSubmit: -> @locked = no


  setFocus: -> @input.focus()


  create: ({body, clientRequestId}, callback) ->

    { activity } = @getOptions()

    { appManager } = KD.singletons

    appManager.tell 'Activity', 'reply', {activity, body, clientRequestId}, (err, reply) =>

      return KD.showError err  if err

      callback err, reply


  inputFocused: ->

    @emit 'Focused'
    KD.mixpanel 'Comment activity, focus'


  inputBlured: ->

    return  unless @input.getValue() is ''
    @emit 'Blured'


  mention: (username) ->

    value = @input.getValue()

    @input.unsetClass 'placeholder'

    @input.setContent \
      if value.indexOf("@#{username}") >= 0 then value
      else if value.length is 0 then "@#{username}&nbsp;"
      else "#{value} @#{username}&nbsp;"

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
          width : 38
          height: 38
      , KD.whoami()

    @addSubView @input
    @addSubView @embedBox

