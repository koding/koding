class ReplyInputWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.cssClass       = KD.utils.curry 'reply-input-widget', options.cssClass
    options.placeholder    = ''
    options.inputViewClass = ReplyInputView

    super options, data


  initEvents: ->
    @input.on "Escape", @bound "reset"
    @input.on "Enter",  @bound "submit"
    @input.on "keyup", =>
      @showPreview() if @preview #Updates preview if it exists

    @forwardEvent @input, 'Enter'


  createSubViews: ->
    { inputViewClass, defaultValue, placeholder } = @getOptions()
    data = @getData()

    @input    = new inputViewClass {defaultValue, placeholder}
    @embedBox = new EmbedBoxWidget delegate: @input, data
    @icon     = new KDCustomHTMLView tagName : 'figure'


  lockSubmit: -> @locked = yes


  unlockSubmit: -> @locked = no


  empty: -> @input.empty()


  create: ({body, clientRequestId}, callback) ->

    {channel: {id: channelId}}  =  @getOptions()

    {appManager} = KD.singletons
    appManager.tell 'Activity', 'sendPrivateMessage', {channelId, body, clientRequestId}, (err, reply) =>
      return KD.showError err  if err

      callback err, reply.first.lastMessage


  viewAppended: ->

    @addSubView @icon
    @addSubView @input

