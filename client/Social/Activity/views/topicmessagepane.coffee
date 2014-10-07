class TopicMessagePane extends MessagePane

  constructor: (options = {}, data) ->

    options.wrapper    ?= no
    options.scrollView ?= no

    super options, data

    KD.singletons.socialapi
      .on 'MessageAdded',   @bound 'addMessage'
      .on 'MessageRemoved', @bound 'removeMessage'

    @filterLinks = null


  addMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message


  removeMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message

  defaultFilter: 'Most Recent'
