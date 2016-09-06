kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
ActivityInputWidget = require '../activityinputwidget'
EmbedBoxWidget = require '../embedboxwidget'
ReplyInputView = require './replyinputview'
showError = require 'app/util/showError'


module.exports = class ReplyInputWidget extends ActivityInputWidget

  {noop, log} = kd
  UPARROW     = 38

  constructor: (options = {}, data) ->

    options.cssClass       = kd.utils.curry 'reply-input-widget', options.cssClass
    options.placeholder    = ''
    options.inputViewClass = ReplyInputView

    super options, data

    @addSubView @input


  initEvents: ->
    @input.on 'Escape', @bound 'reset'
    @input.on 'Enter',  @bound 'submit'
    @input.on 'keyup', (event) =>
      @showPreview() if @preview #Updates preview if it exists
      if event.keyCode is UPARROW and not event.altKey and @input.getValue().trim() is ''
        @emit 'EditModeRequested'

    @on 'SubmitStarted', => kd.utils.defer @bound 'focus'


  createSubViews: ->

    { inputViewClass, defaultValue, placeholder } = @getOptions()
    data = @getData()

    @input    = new inputViewClass {defaultValue, placeholder}
    @embedBox = new EmbedBoxWidget delegate: @input, data
    @icon     = new KDCustomHTMLView tagName : 'figure'


  lockSubmit: -> @locked = yes


  unlockSubmit: -> @locked = no


  empty: -> @input.empty()

  # until we have a different type for collab messages - SY
  getPayload: ->
    return collaboration : yes  if @getOptions().collaboration
    super


  create: (options, callback) ->

    {channel: {id: channelId}} = @getOptions()

    options.channelId = channelId

    @sendPrivateMessage options, callback


  sendPrivateMessage: (options, callback) ->

    {appManager} = kd.singletons
    appManager.tell 'Activity', 'sendPrivateMessage', options, (err, reply) =>
      return showError err  if err

      callback err, reply.first.lastMessage


  viewAppended: ->
