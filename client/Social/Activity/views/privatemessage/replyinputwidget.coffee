class ReplyInputWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.cssClass       = KD.utils.curry 'reply-input-widget', options.cssClass
    options.placeholder    = ''
    options.inputViewClass = ReplyInputView

    super options, data

    @addSubView @input


  initEvents: ->
    @input.on 'Escape', @bound 'reset'
    @input.on 'Enter',  @bound 'submit'
    @input.on 'keyup', (event) =>
      @showPreview() if @preview #Updates preview if it exists
      if event.keyCode is 38 and not event.altKey and @input.getValue().trim() is ''
        @emit 'EditModeRequested'

    @on 'SubmitStarted', => KD.utils.defer @bound 'focus'

  createSubViews: ->
    { inputViewClass, defaultValue, placeholder } = @getOptions()
    data = @getData()

    @input    = new inputViewClass {defaultValue, placeholder}
    @embedBox = new EmbedBoxWidget delegate: @input, data
    @icon     = new KDCustomHTMLView tagName : 'figure'


  lockSubmit: -> @locked = yes


  unlockSubmit: -> @locked = no


  empty: -> @input.empty()


  getPayload: ->


  reset: (unlock = yes) ->

    @input.empty()
    @embedBox.resetEmbedAndHide()

    if unlock then @unlockSubmit()
    else KD.utils.wait 8000, @bound 'unlockSubmit'

  create: ({body, clientRequestId}, callback) ->

    {channel: {id: channelId}}  =  @getOptions()

    {appManager} = KD.singletons
    appManager.tell 'Activity', 'sendPrivateMessage', {channelId, body, clientRequestId}, (err, reply) =>
      return KD.showError err  if err

      callback err, reply.first.lastMessage


  viewAppended: ->

