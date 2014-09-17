class PrivateMessageInputWidget extends ReplyInputWidget

  create: ({body, clientRequestId}, callback) ->

    form = @getOption 'form'

    {autoComplete, inputs: {purpose}} = form

    body       = @input.getValue()
    purpose    = purpose.getValue()
    recipients = (nickname for {profile: {nickname}} in autoComplete.getSelectedItemData())

    {router, socialapi, windowController} = KD.singletons

    socialapi.message.initPrivateMessage {body, recipients, purpose}, (err, channels) =>

      return KD.showError err  if err

      [channel] = channels
      router.handleRoute "/Activity/Message/#{channel.id}"
