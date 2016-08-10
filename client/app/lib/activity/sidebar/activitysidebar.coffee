kd                              = require 'kd'
whoami                          = require '../../util/whoami'
remote                          = require('../../remote').getInstance()
isKoding                        = require 'app/util/isKoding'
showError                       = require '../../util/showError'
groupifyLink                    = require '../../util/groupifyLink'
CustomLinkView                  = require '../../customlinkview'
ChatSearchModal                 = require './chatsearchmodal'
ActivitySideView                = require './activitysideview'
SidebarTopicItem                = require './sidebartopicitem'
isFeatureEnabled                = require 'app/util/isFeatureEnabled'
fetchChatChannels               = require 'app/util/fetchChatChannels'
isSoloProductLite               = require 'app/util/issoloproductlite'
SidebarMessageItem              = require './sidebarmessageitem'
fetchChatChannelCount           = require 'app/util/fetchChatChannelCount'
sortEnvironmentStacks           = require 'app/util/sortEnvironmentStacks'
isChannelCollaborative          = require '../../util/isChannelCollaborative'
SidebarOwnMachinesList          = require './sidebarownmachineslist'
environmentDataProvider         = require 'app/userenvironmentdataprovider'
SidebarSharedMachinesList       = require './sidebarsharedmachineslist'
SidebarStackMachineList         = require './sidebarstackmachinelist'
ChannelActivitySideView         = require './channelactivitysideview'

# this file was once nice and tidy (see https://github.com/koding/koding/blob/dd4e70d88795fe6d0ea0bfbb2ef0e4a573c08999/client/Social/Activity/sidebar/activitysidebar.coffee)
# once we merged two sidebars into one
# activity sidebar became the mainsidebar
# and unfortunately we have too much goin on here right now
# vm menu and activity menu should be separated
# needs a little refactor. - SY

module.exports = class ActivitySidebar extends kd.CustomHTMLView

  revive = (data) ->

    return switch data.typeConstant
      when 'post'  then kd.singletons.socialapi.message.revive { message: data }  #mapActivity
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
      .on 'RouteInfoHandled',          @bound 'deselectAllItems'

    if isKoding()
      notificationController
        .on 'AddedToChannel',            @bound 'accountAddedToChannel'
        .on 'RemovedFromChannel',        @bound 'accountRemovedFromChannel'
        .on 'MessageAddedToChannel',     @bound 'messageAddedToChannel'
        .on 'MessageRemovedFromChannel', @bound 'messageRemovedFromChannel'
        .on 'ReplyAdded',                @bound 'replyAdded'

        .on 'MessageListUpdated',        @bound 'setPostUnreadCount'
        .on 'ParticipantUpdated',        @bound 'handleGlanced'
        .on 'WorkspaceRemoved',          @bound 'updateMachines'
        # .on 'ReplyRemoved',              (update) -> log update.event, update
        # .on 'ChannelUpdateHappened',     @bound 'channelUpdateHappened'

    computeController
      .on 'MachineDataModified',       @bound 'updateMachines'
      .on 'RenderMachines',            @bound 'updateMachines'
      .on 'MachineBeingDestroyed',     @bound 'invalidateWorkspaces'
      .on 'MachineBuilt',              @bound 'machineBuilt'
      .on 'StacksNotConfigured',       @bound 'addStacksNotConfiguredWarning'
      .on 'GroupStacksInconsistent',   @bound 'addGroupStacksChangedWarning'
      .on 'GroupStacksConsistent',     @bound 'hideGroupStacksChangedWarning'

    @on 'ReloadMessagesRequested',     @bound 'handleReloadMessages'

    environmentDataProvider.revive()

    mainController.ready =>
      environmentDataProvider.ensureDefaultWorkspace @bound 'updateMachines'
      notificationController.on 'NewWorkspaceCreated', @bound 'updateMachines'


    @localStorageController = kd.singletons.localStorageController.storage 'Sidebar'


  # event handling

  messageAddedToChannel: (update) ->

    @handleFollowedFeedUpdate update


  messageRemovedFromChannel: (update) ->

    { id } = update.channelMessage

    @removeItem id


  handleGlanced: (update) ->
    { channel } = update

    return  unless channel
    return  unless item = @itemsById[channel.id]

    item.setUnreadCount? update.unreadCount


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


  handleFollowedFeedUpdate: (update) ->

    # WARNING: WRONG NAMING ON THE METHODS
    # these are the situations where we end up here
    #
    # when a REPLY is added to a PRIVATE MESSAGE
    # when a new PRIVATE MESSAGE is posted (because of above i think)
    # when an ACTIVITY is posted to a FOLLOWED TOPIC

    { socialapi }   = kd.singletons
    { unreadCount } = update
    { id }          = update.channel

    socialapi.cacheable 'channel', id, (err, data) =>

      return showError err  if err

      index = switch data.typeConstant
        when 'topic'          then 2
        when 'group'          then 2
        when 'announcement'   then 2
        else 0

      if isFeatureEnabled('botchannel') and data.typeConstant is 'privatemessage'
        index = 1

      unless isChannelCollaborative data
        item = @addItem data, index
        @setUnreadCount item, data, unreadCount


  # when a comment is added to a post
  replyAdded: (update) ->

    { socialapi }   = kd.singletons
    { unreadCount } = update
    { id }          = update.channelMessage
    type            = 'post'

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

    { socialapi }                     = kd.singletons
    { unreadCount, participantCount } = update
    { id, typeConstant }              = update.channel

    socialapi.cacheable typeConstant, id, (err, channel) =>

      return kd.warn err  if err

      channel.isParticipant    = yes
      channel.participantCount = participantCount
      channel.emit 'update'

      isPrivateMessage = typeConstant is 'privatemessage'

      index = 0  if isPrivateMessage

      unless isChannelCollaborative channel
        item = @addItem channel, index
        @setUnreadCount item, channel, unreadCount

        @setFollowingState item, channel.isParticipant


  accountRemovedFromChannel: (update) ->

    { id, typeConstant } = update.channel
    { unreadCount, participantCount } = update
    { socialapi }                     = kd.singletons

    return  if update.isParticipant

    @removeItem id

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

    { unreadCount, channelMessage } = data
    return  unless channelMessage

    { typeConstant, id } = channelMessage

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
      when 'privatemessage', 'bot'   then @sections.messages
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

    for own __, { listController } of @sections

      for item in listController.getListItems()

        data = item.getData()
        { typeConstant, id, name, slug } = data

        if typeConstant is type and slug_ in [id, name, slug]
          candidates.push item

    candidates.sort (a, b) -> a.lastClickedTimestamp < b.lastClickedTimestamp

    if candidates.first
      listController.selectSingleItem candidates.first
      @selectedItem = candidates.first


  deselectAllItems: (route) ->

    @selectedItem = null

    for own name, { listController } of @sections
      listController.deselectAllItems()


  viewAppended: ->

    super

    @addMachineList()

    kd.singletons.mainController.ready =>
      if not isSoloProductLite()
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

    environmentDataProvider.fetch (data) -> callback data


  hideGroupStacksChangedWarning: ->

    @groupStacksChangedWarning?.hide()


  addGroupStacksChangedWarning: ->

    return  if isKoding()

    if @groupStacksChangedWarning and not @groupStacksChangedWarning.isDestroyed
      return @groupStacksChangedWarning.show()

    view = new kd.CustomHTMLView
      cssClass : 'warning-section'
      partial  : """
        <header class='SidebarSection-header'>
          <h4 class='SidebarSection-headerTitle'>STACKS</h4>
        </header>
        <p>
          You have different resources in your stacks.
          Please re-initialize your stacks.
        </p>
      """

    view.addSubView new kd.CustomHTMLView
      tagName: 'a'
      partial: 'Show Stacks'
      attributes: { href: '/Stacks' }

    @groupStacksChangedWarning = \
      @machinesWrapper.addSubView view, null, yes


  addStacksNotConfiguredWarning: ->

    return  if isKoding()
    return  @showStacksNotConfiguredWarning()  if @stacksNotConfiguredWarning?

    currentGroup = kd.singletons.groupsController.getCurrentGroup()
    currentGroup.fetchMyRoles (err, roles) =>
      return kd.warn err  if err

      if 'admin' in (roles ? [])
        partial = """
          <header class='SidebarSection-header'>
            <h4 class='SidebarSection-headerTitle'>STACKS</h4>
          </header>
          <div class='no-stacks'>
            <label>No stacks</label>
            <a href='/Admin/Stacks'>Create a stack</a>
          </div>
          """
      else
        partial = """
          <header class='SidebarSection-header'>
            <h4 class='SidebarSection-headerTitle'>STACKS</h4>
          </header>
          <p>
            Your stacks has not been<br/>
            fully configured yet, please<br/>
            contact your team admin.
          </p>
          """

      cssClass = 'warning-section hidden'
      view     = new kd.CustomHTMLView { cssClass, partial }

      unless 'admin' in (roles ? [])
        view.addSubView new kd.CustomHTMLView
          tagName: 'a'
          partial: 'Message admin'
          attributes: { href: '/Messages/New' }
          click: (event) ->
            kd.utils.stopDOMEvent event

      @stacksNotConfiguredWarning = @machinesWrapper.addSubView view, null, yes

      @showStacksNotConfiguredWarning()


  showStacksNotConfiguredWarning: ->

    @stacksNotConfiguredWarning.show()

  # this part is for when there was a stack before
  # but removed later. disabled until we have a complete ux - SY

  #   { groupsController } = kd.singletons
  #   { stackTemplates }   = globals.currentGroup

  #   if not stackTemplates
  #     kd.singletons.router.handleRoute '/Welcome'
  #   else if Array.isArray stackTemplates and stackTemplates.length is 0
  #     @showStacksNotConfiguredModal 'warning'


  # showStacksNotConfiguredModal: (type) ->

  #   new SidebarStacksNotConfiguredPopup


  addMachineList: (expandedBoxUIds) ->

    @machineLists = []
    @machineListsByName = {}

    unless @machinesWrapper
      @addSubView @machinesWrapper = new kd.CustomHTMLView
        cssClass: 'machines-wrapper'

    @createDefaultMachineList expandedBoxUIds
    @createSharedMachineList()


  createDefaultMachineList: (expandedBoxUIds) ->

    @createMachineList 'own'

    if environmentDataProvider.hasData()
      @addMachines_ environmentDataProvider.get(), expandedBoxUIds
    else
      environmentDataProvider.fetch (data) =>
        @addMachines_ data, expandedBoxUIds


  createSharedMachineList: ->

    machines = environmentDataProvider.getSharedMachines()
    @createMachineList 'shared', {}, machines


  createStackMachineList: do (inProgress = no) -> (expandedBoxUIds) ->

    return  if inProgress

    inProgress = yes

    { computeController } = kd.singletons

    computeController.fetchStacks (err, stacks) =>

      return showError err  if err

      stacks = sortEnvironmentStacks stacks

      stacks.forEach (stack) =>

        { title } = stack

        environmentMap = {}

        for node in environmentDataProvider.getMyMachines()
          environmentMap[node.machine._id] = node

        stackEnvironment = stack.machines
          .map (machine) -> environmentMap[machine._id]
          .filter Boolean

        type = switch
          when title is 'Managed VMs' then 'own'
          else 'stack'

        options = { title, stack }

        @createMachineList type, options, stackEnvironment
        @createSharedMachineList()
        @bindStackEvents stack

      inProgress = no


  bindStackEvents: (stack) ->

    stack.on 'update', @lazyBound 'handleStackUpdate', stack


  handleStackUpdate: (stack) ->

    stack.machines
      .map (machine) => @getMachineBoxByMachineUId machine.uid
      .forEach (box) ->
        return  unless box
        visibility = stack.config.sidebar?[box.machine.uid]?.visibility
        box?.setVisibility visibility ? on


  redrawMachineList: ->

    expandedBoxUIds = @getExpandedBoxUIds()
    @machinesWrapper.destroySubViews()
    @addMachineList expandedBoxUIds

    frontApp = kd.singletons.appManager.getFrontApp()

    if frontApp?.options.name is 'IDE'
      frontApp.whenMachineReady (machine, workspace) =>
        @selectWorkspace { machine, workspace }  if machine and workspace


  addBoxes: (listType, data) ->

    return  if not data or data.length is 0

    machineList = @getMachineList listType
    machineList.addMachineBoxes data
    machineList.on 'ListStateChanged', @bound 'saveSidebarStateToLocalStorage'


  addMachines_: (data, expandedBoxUIds = {}) ->

    @addBoxes 'own', data.own

    if Object.keys(expandedBoxUIds).length is 0
      expandedBoxUIds = @localStorageController.getValue('SidebarState') or {}

    @expandWorkspaceLists expandedBoxUIds
    @saveSidebarStateToLocalStorage()

    @isMachinesListed = yes
    @emit 'MachinesListed'


  saveSidebarStateToLocalStorage: ->

    @localStorageController.setValue 'SidebarState', @getExpandedBoxUIds()


  getMachineList: (type) ->

    return  list  if list = @machineListsByName[type]
    return  @createMachineList type


  createMachineList: (type, options = {}, data = []) ->

    MachineListClasses =
      own              : SidebarOwnMachinesList
      shared           : SidebarSharedMachinesList
      stack            : SidebarStackMachineList

    list = new MachineListClasses[type] options, data

    @machineLists.push list
    @machineListsByName[type] = list

    @machinesWrapper.addSubView list

    return list


  addFollowedTopics: ->

    limit = 10

    @addSubView @sections.channels = new ChannelActivitySideView
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


  handleReloadMessages: ->

    environmentDataProvider.fetch => @sections.messages.reload()


  updateMachines: (callback = kd.noop) ->

    kd.singletons.mainController.ready =>
      @fetchEnvironmentData (data) =>
        @redrawMachineList()
        @emit 'MachinesUpdated'


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

    for machineList in @machineLists
      for machineBox in machineList.machineBoxes
        if machineBox.machine.uid is uid
          return machineBox


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


  showManagedMachineAddedModal: (info, machine) ->

    box = @getMachineBoxByMachineUId machine.uid
    box.machineItem.showMachineConnectedPopup info
