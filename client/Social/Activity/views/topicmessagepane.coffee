class TopicMessagePane extends MessagePane

  constructor: (options = {}, data) ->

    options.cssClass    = KD.utils.curry 'activity-pane', options.cssClass
    options.wrapper    ?= yes
    options.scrollView ?= yes

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
