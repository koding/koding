kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDCustomScrollView = kd.CustomScrollView
KDTabPaneView = kd.TabPaneView
ActivityInputWidget = require './activityinputwidget'
ActivityListController = require '../activitylistcontroller'
ActivityListItemView = require './activitylistitemview'
FilterLinksView = require './filterlinksview'
getMessageOwner = require 'app/util/getMessageOwner'
filterTrollActivity = require 'app/util/filterTrollActivity'
generateDummyMessage = require 'app/util/generateDummyMessage'
isMyPost = require 'app/util/isMyPost'
showError = require 'app/util/showError'
Promise = require 'bluebird'
TopicFollowButton = require 'app/commonviews/topicfollowbutton'

module.exports = class MessagePane extends KDTabPaneView

  {noop} = kd

  constructor: (options = {}, data) ->

    options.type        or= ''
    options.lastToFirst  ?= no
    options.scrollView   ?= yes
    options.itemClass   or= ActivityListItemView

    options.cssClass = kd.utils.curry "message-pane #{options.type}", options.cssClass

    super options, data

    @fetching = no

    @lastScrollTops =
      window        : 0
      parent        : 0
      self          : 0
      body          : 0

    { itemClass, lastToFirst, wrapper, channelId
      scrollView, noItemFoundWidget, startWithLazyLoader
    } = @getOptions()

    {typeConstant} = @getData()

    @listController = new ActivityListController {
      type          : typeConstant
      viewOptions   :
        itemOptions : {channelId}
      wrapper
      itemClass
      lastToFirst
      scrollView
      noItemFoundWidget
      startWithLazyLoader
    }

    @listController.getView().setClass 'padded'

    @createChannelTitle()
    @createInputWidget()
    @createScrollView()
    @createFilterLinks()
    @bindLazyLoader()
    @bindInputEvents()

    @submitIsPending = no

    @fakeMessageMap = {}

    @setFilter @getDefaultFilter()

    {
      socialapi
      notificationController
    } = kd.singletons
    @once 'ChannelReady', @bound 'bindChannelEvents'
    socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    kd.singletons.windowController.addFocusListener @bound 'handleFocus'

    notificationController
      .on 'AddedToChannel',     @bound 'accountAddedToChannel'
      .on 'RemovedFromChannel', @bound 'accountRemovedFromChannel'


  refreshContent: ->

    return  if @fetching

    @listController.showLazyLoader()
    @populate()


  createScrollView: ->

    @scrollView = new KDCustomScrollView
      cssClass          : 'message-pane-scroller'
      lazyLoadThreshold : 100


  bindLazyLoader: ->

    @scrollView.wrapper.on 'LazyLoadThresholdReached', => @emit 'NeedsMoreContent'


  bindInputEvents: ->

    return  unless @input

    @input
      .on 'SubmitStarted',    => @submitIsPending = yes
      .on 'SubmitStarted',    @bound 'handleEnter'
      .on 'SubmitSucceeded',  @bound 'replaceFakeItemView'
      .on 'SubmitSucceeded',  => kd.utils.defer => @submitIsPending = no
      .on 'SubmitFailed',     @bound 'messageSubmitFailed'

  whenSubmitted: ->
    new Promise (resolve) =>
      unless @submitIsPending
        resolve()
      else
        @input.once 'SubmitSucceeded', -> resolve()


  replaceFakeItemView: (message) ->

    @putMessage message, @removeFakeMessage message.clientRequestId


  removeFakeMessage: (identifier) ->

    return  unless item = @fakeMessageMap[identifier]

    index = @listController.getListView().getItemIndex item

    @listController.removeItem item

    return index


  handleEnter: (value, clientRequestId) ->

    return  unless value

    @input.reset yes

    switch @currentFilter
      when 'Most Liked' then @setFilter 'Most Recent'
      else @createFakeItemView value, clientRequestId


  putMessage: (message, index = 0) -> @listController.addItem message, index


  createFakeItemView: (value, clientRequestId) ->

    fakeData = generateDummyMessage value

    item = @putMessage fakeData

    # save it to a map so that we have a reference
    # to it to be deleted.
    @fakeMessageMap[clientRequestId] = item

    @scrollDown item


  messageSubmitFailed: (err, clientRequestId) ->

    view = @fakeMessageMap[clientRequestId]
    view.showResend()
    view.on 'SubmitSucceeded', (message) =>
      message.clientRequestId = clientRequestId
      @replaceFakeItemView message


  handleFocus: (focused) -> @glance()  if focused and @active


  putNewMessageIndicator: ->


  isPageAtBottom: ->

    {wrapper}    = @scrollView

    height       = wrapper.getHeight()
    scrollHeight = wrapper.getScrollHeight()
    scrollTop    = wrapper.getScrollTop()

    # we can tolerate one line of message here. Therefore
    # even a user scrolls up for a single line, it is considered
    # as bottom of the page.
    return scrollTop + height + 50 >= scrollHeight


  scrollDown: ->


  createChannelTitle: ->

    type = @getOption 'type'

    if type is 'privatemessage' or type is 'post' then return

    {name, isParticipant, typeConstant} = @getData()

    @channelTitleView = new KDCustomHTMLView
      partial    : "##{name}"
      cssClass   : "channel-title #{if isParticipant then 'participant' else ''}"
      attributes :
        testpath : 'channel-title'

    if typeConstant not in ['group', 'announcement']
      @followButton = new TopicFollowButton null, @getData()
      @channelTitleView.addSubView @followButton

  createInputWidget: (placeholder) ->

    return  if @getOption("type") is 'post'

    channel     = @getData()
    {socialapi} = kd.singletons
    attributes  = testpath: 'ActivityInputWidget'

    @input = new ActivityInputWidget { attributes, channel, placeholder }


  createFilterLinks: ->

    type = @getOption 'type'

    if type is 'privatemessage' or type is 'post' then return

    filters = ['Most Liked', 'Most Recent']

    {socialapi} = kd.singletons
    # remove the first item from filters
    filters.shift() if socialapi.isAnnouncementItem @getData().id

    @filterLinks or= new FilterLinksView
      filters: filters
      default: filters[0]

    @filterLinks.on 'FilterSelected', (filter) =>

      @listController.removeAllItems()
      @listController.showLazyLoader()
      @setFilter filter


  bindChannelEvents: (channel) ->

    return  unless channel

    channel
      .on 'MessageAdded',   @bound 'realtimeMessageArrived'
      .on 'MessageRemoved', @bound 'removeMessage'


  realtimeMessageArrived: (message) ->

    return  if @currentFilter is 'Most Liked' and not isMyPost message

    {lastToFirst}  = @getOptions()
    index = if lastToFirst then @listController.getItemCount() else 0
    @prependMessage message, index


  loadMessage: (message) ->

    {lastToFirst} = @getOptions()
    index = if lastToFirst then 0 else @listController.getItemCount()
    @appendMessage message, index


  appendMessage: (message, index) -> @listController.addItem message, index


  prependMessage: (message, index, callback = noop) ->

    getMessageOwner message, (err, owner) =>
      return callback err  if err
      return callback() if filterTrollActivity owner
      item = @listController.addItem message, index
      callback null, item


  removeMessage: (message) ->

    listItems = @listController.getListItems()

    [item] = listItems.filter (item) -> item.getData().getId() is message.getId()

    if item?
      item.whenRemovingFinished =>
        @listController.removeItem item
        @listController.showNoItemWidget()  if @listController.getListItems().length is 0

      item.delete()


  setScrollTops: -> @lastScrollTops.scrollView = @scrollView.wrapper.getScrollTop()

  applyScrollTops: -> @scrollView.wrapper.setScrollTop @lastScrollTops.scrollView


  viewAppended: ->

    @addSubView @scrollView
    @scrollView.wrapper.addSubView @channelTitleView  if @channelTitleView
    @scrollView.wrapper.addSubView @input             if @input
    @scrollView.wrapper.addSubView @filterLinks       if @filterLinks
    @scrollView.wrapper.addSubView @listController.getView()
    @setScrollTops()


  show: ->

    super

    kd.utils.wait 1000, @bound 'glance'
    kd.utils.wait 50, => @scrollView.wrapper.emit 'MutationHappened'


  glance: ->

    {socialapi, appManager}  = kd.singletons
    {id, typeConstant, name} = @getData()

    app  = appManager.get 'Activity'
    item = app.getView().sidebar.selectedItem

    return  unless item?.count

    # do not wait for response to set it as 0
    item.setUnreadCount 0

    # no need to send updatelastSeenTime or glance when checking publicfeeds
    return  if name in ['public', 'announcement']

    if typeConstant is 'post'
    then socialapi.channel.glancePinnedPost   messageId : id, @bound 'glanced'
    else socialapi.channel.updateLastSeenTime channelId : id, @bound 'glanced'


  glanced: ->

    @separator?.destroy()
    @separator = null

  focus: ->

  populate: (callback = noop) ->

    filter = @currentFilter

    @fetch null, (err, items = []) =>

      return showError err  if err
      return  if @currentFilter isnt filter

      @listController.removeAllItems()  if @listController.getItemCount()
      @addItems items

      callback()
      @fetching = no


  addMessageDeferred: (item, i, total) ->

    kd.utils.defer =>
      @appendMessage item
      if i is total - 1
        kd.utils.wait 50, => @emit 'ListPopulated'


  addItems: (items) ->
    @listController.hideLazyLoader()
    items.forEach (item, i) =>
      @addMessageDeferred item, i, items.length

    kd.utils.defer @bound 'focus'


  fetch: (options = {}, callback) ->

    {
      name
      type
      channelId
    }            = @getOptions()
    data         = @getData()
    {appManager} = kd.singletons

    options.name      = name
    options.type      = type
    options.channelId = channelId

    @fetching = yes

    @whenSubmitted().then ->
      # if it is a post it means we already have the data
      if type is 'post'
      then kd.utils.defer -> callback null, [data]
      else appManager.tell 'Activity', 'fetch', options, callback


  lazyLoad: do ->

    loading = no

    (listController, callback) ->

      return  if loading

      listController ?= @listController
      listController.showLazyLoader()
      {appManager} = kd.singletons
      last         = listController.getListItems().last

      return listController.hideLazyLoader()  unless last

      loading = yes

      if @currentFilter is 'Most Liked'
        from = null
        skip = listController.getItemCount()
      else
        from = last.getData().createdAt

      @fetch {from, skip}, (err, items = []) =>
        loading = no
        listController.hideLazyLoader()

        showError err  if err

        callback err, items


  setFilter: (filter) ->

    return  if @currentFilter is filter

    @filterLinks.selectFilter @currentFilter
    @populate()


  getDefaultFilter:->

    {socialapi} = kd.singletons

    if socialapi.isAnnouncementItem @getData().id
    then 'Most Recent'
    else 'Most Liked'


  accountAddedToChannel: (update) ->

    { id } = update.channel

    if @followButton and id is @followButton.getData().id
      @followButton.setFollowingState yes


  accountRemovedFromChannel: (update) ->

    { id } = update.channel

    if @followButton and id is @followButton.getData().id
      @followButton.setFollowingState no
