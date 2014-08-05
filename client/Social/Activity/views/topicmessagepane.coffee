class TopicMessagePane extends MessagePane

  bindChannelEvents: ->

    KD.singletons.socialapi
      .on 'MessageAdded',   @bound 'prependMessage'
      .on 'MessageRemoved', @bound 'removeMessage'


  prependMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message


  removeMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message
