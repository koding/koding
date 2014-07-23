class ReplyInputWidget extends ActivityInputWidget

  constructor: (options = {}, data) ->

    options.placeholder or= "Type your reply and hit enter..."

    super options, data

  viewAppended: ->

    @addSubView @icon
    @addSubView @input
    # @addSubView @buttonBar
    # @addSubView @bugNotification
    # @addSubView @helpContainer
    # @buttonBar.addSubView @submitButton
    # @buttonBar.addSubView @previewIcon

  create: ({body}, callback) ->

    {channel:{id: channelId}}  =  @getOptions()

    {appManager} = KD.singletons
    appManager.tell 'Activity', 'sendPrivateMessage', {channelId, body}, (err, reply) =>
      return KD.showError err  if err
      callback()