class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    {itemClass, type} = @getOptions()
    lastToFirst = yes  unless type is "message"

    @listController = new ActivityListController {itemClass, lastToFirst}
    @createInputWidget()

    @bindChannelEvents()


  bindChannelEvents: ->

    {channel} = @getData()
    channel  ?= KD.singleton("socialapi").openedChannels[@getOption "name"]

    return  unless channel

    channel.on "MessageAdded", @bound "addMessage"
    channel.on "MessageRemoved", @bound "removeMessage"


  addMessage: (message) ->

    @listController.addItem message


  removeMessage: (message) ->

    @listController.removeItem message


  viewAppended: ->

    @addSubView @input  if @input
    @addSubView @listController.getView()
    @populate()


  populate: ->

    @fetch (err, items = []) =>

      return KD.showError err  if err

      console.time('populate')
      @listController.hideLazyLoader()
      @listController.instantiateListItems items.reverse()
      console.timeEnd('populate')


  fetch: (callback)->

    {appManager}            = KD.singletons
    {name, type, channelId} = @getOptions()
    data                    = @getData()
    options                 = {name, type, channelId}

    # if it is a post it means we already have the data
    if type is 'post'
    then KD.utils.defer -> callback null, [data]
    else appManager.tell 'Activity', 'fetch', options, callback


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()


  createInputWidget: ->

    return  if @getOption("type") in ["post", "message"]

    channel = @getData()

    @input = new ActivityInputWidget {channel}
    @input.on 'Submit', @listController.bound 'addItem'
