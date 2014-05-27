class TopicMessagePane extends MessagePane

  bindChannelEvents: ->

    super

    KD.singletons.socialapi
      .on 'MessageAdded', @bound 'addMessage'
      .on 'MessageRemoved', @bound 'removeMessage'


  addMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message


  removeMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message
