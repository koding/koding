class PrivateMessageInputWidget extends ReplyInputWidget

  create: ({body, clientRequestId}, callback) ->

    form = @getOption 'form'

    {fields : {body, purpose}} = form
    {buttons: {send}}          = form

    body       = body.getValue()
    purpose    = purpose.getValue()
    recipients = (nickname for {profile: {nickname}} in @autoComplete.getSelectedItemData())

    {router, socialapi, windowController} = KD.singletons

    socialapi.message.initPrivateMessage {body, recipients, purpose}, (err, channels) =>

      send.hideLoader()

      return KD.showError err  if err

      [channel] = channels
      router.handleRoute "/Activity/Message/#{channel.id}"
