class TopicMessagePane extends MessagePane

  constructor: (options = {}, data) ->

    super options, data

    KD.singletons.socialapi
      .on 'MessageAdded',   @bound 'addMessage'
      .on 'MessageRemoved', @bound 'removeMessage'


  addMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message


  removeMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message
