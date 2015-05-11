kd                        = require 'kd'
nick                      = require '../../util/nick'
whoami                    = require '../../util/whoami'
remote                    = require('../../remote').getInstance()
globals                   = require 'globals'
Promise                   = require 'bluebird'
sinkrow                   = require 'sinkrow'
Machine                   = require 'app/providers/machine'
FSHelper                  = require '../../util/fs/fshelper'
showError                 = require '../../util/showError'
MoreVMsModal              = require './morevmsmodal'
groupifyLink              = require '../../util/groupifyLink'
ComputeHelpers            = require 'app/providers/computehelpers'
CustomLinkView            = require '../../customlinkview'
ChatSearchModal           = require './chatsearchmodal'
ActivitySideView          = require './activitysideview'
KDCustomHTMLView          = kd.CustomHTMLView
SidebarTopicItem          = require './sidebartopicitem'
fetchChatChannels         = require 'activity/util/fetchChatChannels'
SidebarPinnedItem         = require './sidebarpinneditem'
KDNotificationView        = kd.NotificationView
SidebarMessageItem        = require './sidebarmessageitem'
JTreeViewController       = kd.JTreeViewController
MoreWorkspacesModal       = require './moreworkspacesmodal'
fetchChatChannelCount     = require 'activity/util/fetchChatChannelCount'
isChannelCollaborative    = require '../../util/isChannelCollaborative'
SidebarOwnMachinesList    = require './sidebarownmachineslist'
environmentDataProvider   = require 'app/userenvironmentdataprovider'
SidebarSharedMachinesList = require './sidebarsharedmachineslist'
isFeatureEnabled          = require 'app/util/isFeatureEnabled'

# this file was once nice and tidy (see https://github.com/koding/koding/blob/dd4e70d88795fe6d0ea0bfbb2ef0e4a573c08999/client/Social/Activity/sidebar/activitysidebar.coffee)
# once we merged two sidebars into one
# activity sidebar became the mainsidebar
# and unfortunately we have too much goin on here right now
# vm menu and activity menu should be separated
# needs a little refactor. - SY

module.exports = class ActivitySidebar extends KDCustomHTMLView

  typeMap =
    privatemessage : 'Message'
    topic          : 'Topic'
    post           : 'Post'
    chat           : 'Chat'

  slugProps =
    SocialMessage : 'slug'
    SocialChannel : 'name'

  revive = (data) ->

    return switch data.typeConstant
      when 'post'  then kd.singletons.socialapi.message.revive message: data  #mapActivity
      when 'topic' then kd.singletons.socialapi.channel.revive data
      else data


  constructor: (options = {}) ->

    options.cssClass     = 'activity-sidebar'
    options.maxListeners = 20

    super options

    {
      mainController
      notificationController
      computeController
      socialapi
      router
    } = kd.singletons

    @sections     = {}
    @itemsById    = {}
    @itemsBySlug  = {}
    @itemsByName  = {}
    @selectedItem = null

    # @appsList = new DockController

    router
      .on "RouteInfoHandled",          @bound 'deselectAllItems'

    notificationController
      .on 'AddedToChannel',            @bound 'accountAddedToChannel'
      .on 'RemovedFromChannel',        @bound 'accountRemovedFromChannel'
      .on 'MessageAddedToChannel',     @bound 'messageAddedToChannel'
      .on 'MessageRemovedFromChannel', @bound 'messageRemovedFromChannel'
      .on 'ReplyAdded',                @bound 'replyAdded'

      .on 'MessageListUpdated',        @bound 'setPostUnreadCount'
      .on 'ParticipantUpdated',        @bound 'handleGlanced'
      # .on 'ReplyRemoved',              (update) -> log update.event, update
      # .on 'ChannelUpdateHappened',     @bound 'channelUpdateHappened'

    computeController
      .on 'MachineDataModified',       @bound 'updateMachines'
      .on 'RenderMachines',            @bound 'updateMachines'
      .on 'MachineBeingDestroyed',     @bound 'invalidateWorkspaces'
      .on 'MachineBuilt',              @bound 'machineBuilt'

    @on 'ReloadMessagesRequested',     @bound 'handleReloadMessages'

    environmentDataProvider.revive()

    mainController.ready =>
      environmentDataProvider.ensureDefaultWorkspace @bound 'updateMachines'
      whoami().on 'NewWorkspaceCreated', @bound 'updateMachines'


    @localStorageController = kd.singletons.localStorageController.storage 'Sidebar'


  # event handling

  messageAddedToChannel: (update) ->

    { channel, channelMessage, unreadCount } = update

    if isChannelCollaborative(channel) and channelMessage.payload
      if channelMessage.payload['system-message'] in ['start', 'stop']
        @fetchEnvironmentData =>
          @setWorkspaceUnreadCount channel, unreadCount

    @handleFollowedFeedUpdate update


  messageRemovedFromChannel: (update) ->

    {id} = update.channelMessage

    @removeItem id


  handleGlanced: (update) ->
    { channel } = update

    return  unless channel
    return  unless item = @itemsById[channel.id]

    item.setUnreadCount? update.unreadCount


  glanceChannelWorkspace: (channel) ->

    @setWorkspaceUnreadCount channel, 0


  setUnreadCount: (item, data, unreadCount) ->

    return  unless item

    { windowController, appManager } = kd.singletons

    app = appManager.getFrontApp()

    if app?.getOption('name') is 'Activity'
      pane    = app.getView().tabs.getActivePane()
      channel = pane.getData()

      return  unless channel

      inCurrentPane = channel.id is data.id

      if inCurrentPane and windowController.isFocused() and pane.isPageAtBottom()
        return pane.glance()
      else
        pane.putNewMessageIndicator()

    item.setUnreadCount? unreadCount


  setWorkspaceUnreadCount: (data, count) ->

    channelId = data._id
    provider  = environmentDataProvider

    provider.fetchMachineAndWorkspaceByChannelId channelId, (machine, workspace) =>

      return  unless machine and workspace
      return  unless box = @getMachineBoxByMachineUId machine.uid
      box.setUnreadCount channelId, count


  handleFollowedFeedUpdate: (update) ->

    # WARNING: WRONG NAMING ON THE METHODS
    # these are the situations where we end up here
    #
    # when a REPLY is added to a PRIVATE MESSAGE
    # when a new PRIVATE MESSAGE is posted (because of above i think)
    # when an ACTIVITY is posted to a FOLLOWED TOPIC

    {socialapi}   = kd.singletons
    {unreadCount} = update
    {id}          = update.channel

    socialapi.cacheable 'channel', id, (err, data) =>

      return showError err  if err

      index = switch data.typeConstant
        when 'topic'          then 2
        when 'group'          then 2
        when 'announcement'   then 2
        else 0

      if isFeatureEnabled('botchannel') and data.typeConstant is 'privatemessage'
        index = 1

      if isChannelCollaborative data
        @setWorkspaceUnreadCount data, unreadCount
      else
        item = @addItem data, index
        @setUnreadCount item, data, unreadCount


  # when a comment is added to a post
  replyAdded: (update) ->

    {socialapi}   = kd.singletons
    {unreadCount} = update
    {id}          = update.channelMessage
    type          = 'post'

    # so we fetch respectively
    socialapi.cacheable type, id, (err, data) =>

      return showError err  if err

      # when someone replies to a user's post, we locally mark that post, and
      # any cached copies as "followed" by that user.
      socialapi.eachCached data.getId(), (it) -> it.isFollowed = yes
      # and add to the sidebar
      # (if the item is already on sidebar, it's handled on @addItem)
      item = @addItem data, 0
      @setUnreadCount item, data, unreadCount


  accountAddedToChannel: (update) ->

    # WARNING: WRONG NAMING ON THE METHODS
    # these are the situations where we end up here
    #
    # when a new PRIVATE MESSAGE is posted
    # when a TOPIC is followed

    {socialapi}                     = kd.singletons
    {unreadCount, participantCount} = update
    {id, typeConstant}              = update.channel

    socialapi.cacheable typeConstant, id, (err, channel) =>

      return kd.warn err  if err

      channel.isParticipant    = yes
      channel.participantCount = participantCount
      channel.emit 'update'

      isPrivateMessage = typeConstant is 'privatemessage'

      index = 0  if isPrivateMessage

      if isChannelCollaborative channel
        @fetchEnvironmentData (data) =>
          # @sharedMachinesList.updateList data.shared.concat data.collaboration
          @setWorkspaceUnreadCount channel, unreadCount
      else
        item = @addItem channel, index
        @setUnreadCount item, channel, unreadCount

        @setFollowingState item, channel.isParticipant


  accountRemovedFromChannel: (update) ->

    {id, typeConstant} = update.channel
    {unreadCount, participantCount} = update
    {socialapi}                     = kd.singletons

    return  if update.isParticipant

    @removeItem id

    @sharedMachinesList.removeWorkspaceByChannelId id

    # TODO update participants in sidebar
    # TODO I have added these lines for channel data synchronization,
    # but do not think that this is the right place for doing this.
    socialapi.cacheable typeConstant, id, (err, channel) ->

      return kd.warn err  if err

      channel.isParticipant    = no
      channel.participantCount = participantCount
      channel.emit 'update'


  setFollowingState: (item, state) ->

    item.followButton?.setFollowingState state


  channelUpdateHappened: (update) -> kd.warn 'dont use this, :::educational purposes only!:::', update


  setPostUnreadCount: (data) ->

    {unreadCount, channelMessage} = data
    return  unless channelMessage

    {typeConstant, id} = channelMessage

    listController = @getListController typeConstant
    item = listController.itemForId id

    # if we are getting updates about a message it means we are following it
    item.isFollowed = yes if item

    # if we are getting updates about a message that is not in the channel it
    # should be added into list
    @replyAdded data  unless item

    @setUnreadCount item, data, unreadCount


  getItems: ->

    items = []
    items = items.concat @sections.channels.listController.getListItems()
    items = items.concat @sections.messages.listController.getListItems()

    return items


  getListController: (type) ->

    section = switch type
      when 'topic', 'announcement'  then @sections.channels
      when 'privatemessage','bot'   then @sections.messages
      else {}

    return section.listController


  getItemByData: (data) ->

    item = @itemsById[data.id] or
           @itemsBySlug[data.slug] or
           @itemsByName[data.name]

    return item or null


  # dom manipulation

  addItem: (data, index) ->

    listController = @getListController data.typeConstant

    return  unless listController

    item = @getItemByData data

    # add the new topic item in sidebar
    return listController.addItem data, index  unless item

    # since announcement is fixed in sidebar no need to add/move it
    return item  if data.typeConstant is 'announcement'

    # move the channel to the given index
    listController.moveItemToIndex item, index  if index?

    return item


  removeItem: (id) ->

    if item = @itemsById[id]

      data           = item.getData()
      listController = @getListController data.typeConstant

      item.bindTransitionEnd()
      item.once 'transitionend', -> listController.removeItem item
      item.setClass 'out'


  bindItemEvents: (listView) ->

    listView.on 'ItemWasAdded',   @bound 'registerItem'
    listView.on 'ItemWasRemoved', @bound 'unregisterItem'


  registerItem: (item) ->

    data = item.getData()

    @itemsById[data.id]     = item  if data.id
    @itemsBySlug[data.slug] = item  if data.slug
    @itemsByName[data.name] = item  if data.name


  unregisterItem: (item) ->

    data = item.getData()

    if data.id
      @itemsById[data.id] = null
      delete @itemsById[data.id]

    if data.slug
      @itemsBySlug[data.slug] = null
      delete @itemsBySlug[data.id]

    if data.name
      @itemsByName[data.name] = null
      delete @itemsByName[data.name]


  updateTopicFollowButtons: (id, state) ->

    return # until we have either fav or hot lists back - SY

    item  = @sections.hot.listController.itemForId id
    state = if state then 'Unfollow' else 'Follow'
    item?.followButton.setState state


  # fixme:
  # this item selection is a bit tricky
  # depends on multiple parts:
  # - sidebaritem's lastTimestamp
  # - the item which is being clicked
  # - and what the route suggests
  # needs to be simplified
  selectItemByRouteOptions: (type, slug_) ->

    @deselectAllItems()

    type       = 'privatemessage'  if type is 'message'
    type       = 'group'           if slug_ is 'public'
    candidates = []

    for own name_, {listController} of @sections

      for item in listController.getListItems()

        data = item.getData()
        {typeConstant, id, name , slug} = data

        if typeConstant is type and slug_ in [id, name, slug]
          candidates.push item

    candidates.sort (a, b) -> a.lastClickedTimestamp < b.lastClickedTimestamp

    if candidates.first
      listController.selectSingleItem candidates.first
      @selectedItem = candidates.first


  deselectAllItems: (route) ->

    @selectedItem = null

    for own name, {listController} of @sections
      listController.deselectAllItems()


  viewAppended: ->

    super

    @addMachineList()
    @addFollowedTopics()
    @addMessages()


  initiateFakeCounter: ->

    kd.utils.wait 5000, =>
      publicLink = @sections.channels.listController.getListItems().first
      publicLink.setClass 'unread'
      publicLink.unreadCount.updatePartial 1
      publicLink.unreadCount.show()

      publicLink.on 'click', ->
        kd.utils.wait 177, ->
          publicLink.unsetClass 'unread'
          publicLink.unreadCount.hide()


  selectWorkspace: (data) ->

    { machine, workspace } = data

    kd.getSingleton('mainController').ready =>

      for machineList in @machineLists
        machineList.selectMachineAndWorkspace machine.uid, workspace.slug


  fetchEnvironmentData: (callback) ->

    environmentDataProvider.fetch (data) => callback data


  addMachineList: (expandedBoxUIds) ->

    @machineLists = []
    @machineListsByName = {}

    unless @machinesWrapper
      @addSubView @machinesWrapper = new KDCustomHTMLView
        cssClass: 'machines-wrapper'

    @ownMachinesList    = @createMachineList 'own'
    @sharedMachinesList = @createMachineList 'shared'

    if environmentDataProvider.hasData()
      @addMachines_ environmentDataProvider.get(), expandedBoxUIds
    else
      environmentDataProvider.fetch (data) =>
        @addMachines_ data, expandedBoxUIds


  redrawMachineList: ->

    expandedBoxUIds = @getExpandedBoxUIds()
    @machinesWrapper.destroySubViews()
    @addMachineList expandedBoxUIds

    frontApp = kd.singletons.appManager.getFrontApp()

    if frontApp?.options.name is 'IDE'
      frontApp.whenMachineReady (machine, workspace) =>
        @selectWorkspace { machine, workspace }  if machine and workspace


  addBoxes: (machineList, data) ->

    machineList.addMachineBoxes data
    machineList.on 'ListStateChanged', @bound 'saveSidebarStateToLocalStorage'


  addMachines_: (data, expandedBoxUIds = {}) ->

    { shared, collaboration } = data
    sharedData = shared.concat collaboration

    @addBoxes @ownMachinesList, data.own
    @addBoxes @sharedMachinesList, sharedData

    if Object.keys(expandedBoxUIds).length is 0
      expandedBoxUIds = @localStorageController.getValue('SidebarState') or {}

    @expandWorkspaceLists expandedBoxUIds
    @saveSidebarStateToLocalStorage()

    @isMachinesListed = yes
    @emit 'MachinesListed'


  saveSidebarStateToLocalStorage: ->

    @localStorageController.setValue 'SidebarState', @getExpandedBoxUIds()


  createMachineList: (type, options = {}, data = []) ->

    MachineListClasses =
      own              : SidebarOwnMachinesList
      shared           : SidebarSharedMachinesList

    list = new MachineListClasses[type] options, data

    @machineLists.push list
    @machineListsByName[type] = list

    @machinesWrapper.addSubView list

    return list


  addFollowedTopics: ->

    limit = 10

    @addSubView @sections.channels = new ActivitySideView
      title      : 'Channels'
      cssClass   : 'followed topics'
      itemClass  : SidebarTopicItem
      dataPath   : 'followedChannels'
      delegate   : this
      noItemText : 'You don\'t follow any topics yet.'
      searchLink : '/Activity/Topic/Following'
      limit      : limit
      headerLink : new CustomLinkView
        cssClass : 'add-icon'
        title    : ' '
        href     : groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        kd.singletons.socialapi.channel.fetchFollowedChannels
          limit : limit
        , callback
      countSource: (callback) ->
        remote.api.SocialChannel.fetchFollowedChannelCount {}, callback


  addMessages: ->

    limit = 10

    @addSubView @sections.messages = new ActivitySideView
      title      : 'Messages'
      cssClass   : 'messages'
      itemClass  : SidebarMessageItem
      searchClass: ChatSearchModal
      dataPath   : 'privateMessages'
      delegate   : this
      noItemText : 'nothing here.'
      searchLink : '/Activity/Chat/All'
      limit      : limit
      headerLink : new CustomLinkView
        cssClass : 'add-icon'
        title    : ' '
        href     : groupifyLink '/Activity/Message/New'
      dataSource : (callback) ->
        fetchChatChannels { limit }, callback
      countSource: (callback) ->
        fetchChatChannelCount {}, callback

    @sections.messages.on 'DataReady', @bound 'handleWorkspaceUnreadCounts'


  handleReloadMessages: ->

    environmentDataProvider.fetch => @sections.messages.reload()


  handleWorkspaceUnreadCounts: (chatData) ->

    cb = =>
      chatData.forEach (data) =>
        @setWorkspaceUnreadCount data, data.unreadCount

    if @isMachinesListed then cb()
    else @once 'MachinesListed', cb


  updateMachines: (callback = kd.noop) ->

    kd.singletons.mainController.ready =>
      @fetchEnvironmentData @bound 'redrawMachineList'


  invalidateWorkspaces: (machine) ->

    return  unless machine

    remote.api.JWorkspace.deleteByUid machine.uid, (err) =>

      return kd.warn err  if err

      environmentDataProvider.clearWorkspaces machine
      @redrawMachineList()


  removeMachineNode: (machine) ->

    box = @getMachineBoxByMachineUId machine.uid
    box?.destroy()


  getMachineBoxByMachineUId: (uid) ->

    box = null

    for machineList in @machineLists
      for machineBox in machineList.machineBoxes
        if machineBox.machine.uid is uid
          box = machineBox

    return box


  machineBuilt: ->

    environmentDataProvider.ensureDefaultWorkspace @bound 'updateMachines'


  addWorkspace: (workspace) ->

    machineBox = @getMachineBoxByMachineUId workspace.machineUId
      .addWorkspace workspace, yes


  # Comment for `expandWorkspaceLists` and `getExpandedBoxUIds`
  #
  # These are the methods I added to expand already expanded workspace lists
  # when we redraw the machine lists. On the fly, I create a map of expanded
  # machine uids and pass it to sidebar draw method. Now I feel like,
  # we started again to add methods into this file to do some stuff which
  # they shouldn't be in this file. The proper solution would be creating a
  # sidebar singleton and move all machine related methods to there. I hope
  # I will do it in the future at some point for now let's go with these.
  getExpandedBoxUIds: ->

    uids = {}

    for list in @machineLists
      for box in list.machineBoxes when box.isListCollapsed is no
        uids[box.data.machine.uid] = yes

    return uids


  expandWorkspaceLists: (expandedBoxUIds) ->

    for list in @machineLists
      for box in list.machineBoxes when expandedBoxUIds[box.data.machine.uid]
        box.expandList()
