class ReplyInputWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.placeholder    or= "Type your reply and hit enter..."
    options.inputViewClass or= ReplyInputView

    super options, data
    @setClass "reply-input-widget"

  viewAppended: ->

    @addSubView @icon
    @addSubView @input

  create: ({body}, callback) ->

    {channel:{id: channelId}}  =  @getOptions()

    {appManager} = KD.singletons
    appManager.tell 'Activity', 'sendPrivateMessage', {channelId, body}, (err, reply) =>
      return KD.showError err  if err
      callback()
