class TopicMessagePane extends MessagePane

  constructor: (options = {}, data) ->

    options.cssClass    = KD.utils.curry 'topic-pane activity-pane', options.cssClass
    options.wrapper    ?= no
    options.scrollView ?= no

    super options, data

    KD.singletons.socialapi
      .on 'MessageAdded',   @bound 'addMessage'
      .on 'MessageRemoved', @bound 'removeMessage'

    @filterLinks = null

    @on 'NeedsMoreContent', =>
      @listController.showLazyLoader()

      @lazyLoad null, (err, items) =>

        return err  if err

        @addItems items


  addMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message


  removeMessage: (message) ->

    {name} = @getData()
    return  unless message.body.match ///##{name}///

    super message

  defaultFilter: 'Most Recent'
