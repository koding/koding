class PrivateMessageInputWidget extends ReplyInputWidget

  create: (options = {}, callback) ->

    form = @getOption 'form'

    {autoComplete, inputs: {purpose}} = form

    options.body       = @input.getValue()
    options.purpose    = purpose.getValue()
    options.recipients = (nickname for {profile: {nickname}} in autoComplete.getSelectedItemData())

    {router, socialapi, windowController} = KD.singletons

    socialapi.message.initPrivateMessage options, (err, channels) =>

      return KD.showError err  if err

      [channel] = channels
      router.handleRoute "/Activity/Message/#{channel.id}"
