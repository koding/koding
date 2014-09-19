# this file was once nice and tidy (see https://github.com/koding/koding/blob/dd4e70d88795fe6d0ea0bfbb2ef0e4a573c08999/client/Social/Activity/sidebar/activitysidebar.coffee)
# once we merged two sidebars into one
# activity sidebar became the mainsidebar
# and unfortunately we have too mcuh goin on here right now.
# vm menu and activity menu should be separated,
# needs a little refactor. - SY

class ActivitySidebar extends KDCustomHTMLView


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
      when 'post'  then KD.singletons.socialapi.message.revive message: data  #mapActivity
      when 'topic' then KD.singletons.socialapi.channel.revive data
      else data


  constructor: (options = {}) ->

    options.cssClass  = 'activity-sidebar'

    super options

    {
      notificationController
      computeController
      socialapi
    } = KD.singletons

    @sections     = {}
    @itemsById    = {}
    @itemsBySlug  = {}
    @itemsByName  = {}
    @selectedItem = null

    # @appsList = new DockController

    notificationController
      .on 'AddedToChannel',            @bound 'accountAddedToChannel'
      .on 'RemovedFromChannel',        @bound 'accountRemovedFromChannel'
      .on 'ReplyAdded',                @bound 'replyAdded'
      .on 'MessageAddedToChannel',     @bound 'messageAddedToChannel'
      .on 'MessageRemovedFromChannel', @bound 'messageRemovedFromChannel'

      .on 'MessageListUpdated',        @bound 'setPostUnreadCount'
      .on 'ReplyRemoved',              (update) -> log update.event, update

      .on 'ParticipantUpdated',        @bound 'handleGlanced'
      # .on 'ChannelUpdateHappened',     @bound 'channelUpdateHappened'

    computeController
      .on 'MachineDataModified',       @bound 'updateMachineTree'
      .on 'RenderMachines',            @bound 'renderMachines'

  # event handling

  messageAddedToChannel: (update) ->
    switch update.channel.typeConstant
      when 'pinnedactivity' then @replyAdded update
      else  @handleFollowedFeedUpdate update


  messageRemovedFromChannel: (update) ->

    {id} = update.channelMessage

    @removeItem id


  handleGlanced: (update) -> @selectedItem?.setUnreadCount? update.unreadCount


  handleFollowedFeedUpdate: (update) ->

    {socialapi}   = KD.singletons
    {unreadCount} = update
    {id}          = update.channel

    socialapi.cacheable 'channel', id, (err, data) =>

      return KD.showError err  if err

      item = @addItem data, yes
      item.setUnreadCount unreadCount


  replyAdded: (update) ->

    {socialapi}        = KD.singletons
    {unreadCount}      = update
    {id, typeConstant} = update.channelMessage
    type               = 'post'

    # if the reply is added to a private message
    # we need to get the channel instead of the post
    # the other case of reply being added is followed post
    if typeConstant is 'privatemessage'
      type    = 'channel'
      id      = update.channel.id

    # so we fetch respectively
    socialapi.cacheable type, id, (err, data) =>

      return KD.showError err  if err

      # when someone replies to a user's post, we locally mark that post, and
      # any cached copies as "followed" by that user.
      socialapi.eachCached data.getId(), (it) -> it.isFollowed = yes
      # and add to the sidebar
      # (if the item is already on sidebar, it's handled on @addItem)
      item = @addItem data, yes
      item.setUnreadCount unreadCount


  accountAddedToChannel: (update) ->

    {socialapi}                     = KD.singletons
    {unreadCount, participantCount} = update
    {id, typeConstant}              = update.channel

    socialapi.cacheable typeConstant, id, (err, channel) =>

      return KD.showError err  if err

      item = @addItem channel, yes
      channel.participantCount = participantCount
      channel.emit 'update'
      item.setUnreadCount unreadCount


  accountRemovedFromChannel: (update) ->

    {socialapi}                     = KD.singletons
    {id, typeConstant}              = update.channel
    {unreadCount, participantCount} = update

    # @removeItem id

    socialapi.cacheable typeConstant, id, (err, channel) =>
      channel.participantCount = participantCount
      channel.emit 'update'



  channelUpdateHappened: (update) -> warn 'dont use this, :::educational purposes only!:::', update


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

    item.setUnreadCount unreadCount  if item?.unreadCount


  getItems: ->

    items = []
    items = items.concat @sections.channels.listController.getListItems()
    items = items.concat @sections.conversations.listController.getListItems()
    items = items.concat @sections.messages.listController.getListItems()

    return items


  getListController: (type) ->

    section = switch type
      when 'topic'                  then @sections.channels
      when 'pinnedactivity', 'post' then @sections.conversations
      when 'privatemessage'         then @sections.messages
      else {}

    return section.listController


  getItemByData: (data) ->

    item = @itemsById[data.id] or
           @itemsBySlug[data.slug] or
           @itemsByName[data.name]

    return item or null


  # dom manipulation

  addItem: (data, prepend = no) ->

    index          = if prepend then 0
    listController = @getListController data.typeConstant

    if item = @getItemByData data
      listController.moveItemToIndex item, index

      return item

    item = listController.addItem data, index

    return item


  removeItem: (id) ->

    if item = @itemsById[id]

      data           = item.getData()
      listController = @getListController data.typeConstant

      listController.removeItem item


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
    state = if state then 'Following' else 'Follow'
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


  deselectAllItems: ->

    @selectedItem = null

    for own name, {listController} of @sections
      listController.deselectAllItems()


  viewAppended: ->

    super

    @addVMTree()
    @addFollowedTopics()
    @addConversations()
    @addMessages()


  initiateFakeCounter: ->

    KD.utils.wait 5000, =>
      publicLink = @sections.channels.listController.getListItems().first
      publicLink.setClass 'unread'
      publicLink.unreadCount.updatePartial 1
      publicLink.unreadCount.show()

      publicLink.on 'click', ->
        KD.utils.wait 177, ->
          publicLink.unsetClass 'unread'
          publicLink.unreadCount.hide()



  listMachines: (machines) ->

    treeData = []

    for machine in machines
      treeData.push item = new Machine {machine}
      id = item.getId()
      treeData.push
        title        : 'Workspaces <span class="ws-add-icon"></span>'
        type         : 'title'
        parentId     : id
        id           : machine._id
        machineUId   : machine.uid
        machineLabel : machine.slug or machine.label

      treeData.push
        title        : 'My Workspace'
        type         : 'workspace'
        href         : "/IDE/#{machine.slug or machine.label}/my-workspace"
        id           : "#{machine.slug or machine.label}-workspace"
        parentId     : id
        machineLabel : machine.slug or machine.label

      KD.userWorkspaces.forEach (workspace) ->
        if workspace.machineUId is machine.uid
          treeData.push
            title        : workspace.name
            type         : 'workspace'
            href         : "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
            machineLabel : machine.slug or machine.label
            data         : workspace
            id           : workspace._id
            parentId     : id

    @machineTree.addNode data for data in treeData


  selectWorkspace: (data) ->

    data = @latestWorkspaceData or {}  unless data
    { workspace, machine } = data

    return if not machine or not workspace

    tree = @machineTree

    for key, node of tree.nodes
      nodeData         = node.getData()
      isSameMachine    = nodeData.uid is machine.uid
      isMachineRunning = machine.status.state is Machine.State.Running

      if node.type is 'machine'
        if isSameMachine
          if isMachineRunning
            tree.expand node
          else
            tree.selectNode node
            @watchMachineState workspace, machine
        else
          tree.collapse node

      else if node.type is 'workspace'
        if isMachineRunning and nodeData.machineLabel is (machine.slug or machine.label)
          slug = nodeData.data?.slug or KD.utils.slugify nodeData.title
          tree.selectNode node  if slug is workspace.slug

    @latestWorkspaceData = data

    localStorage         = KD.getSingleton("localStorageController").storage "IDE"
    minimumDataToStore   = machineLabel: (machine.slug or machine.label), workspaceSlug: workspace.slug

    localStorage.setValue 'LatestWorkspace', minimumDataToStore


  watchMachineState: (workspace, machine) ->
    @watchedMachines  or= {}
    computeController   = KD.getSingleton 'computeController'
    appManager          = KD.getSingleton 'appManager'
    isSameMachineActive = appManager.getFrontApp().mountedMachineUId is machine.uid
    {Running}           = Machine.State

    return  if @watchedMachines[machine._id]

    callback = (state) =>
      if state.status is Running
        machine.status.state = Running
        if isSameMachineActive
          @selectWorkspace { workspace, machine }
          delete @watchedMachines[machine._id]

    computeController.on "public-#{machine._id}", callback
    @watchedMachines[machine._id] = yes


  fetchMachines: (callback) ->

    {computeController} = KD.singletons

    # force refetch from server everytime machines fetched.
    computeController.reset()
    computeController.fetchMachines (err, machines)=>
      if err
        ErrorLog.create 'terminal: Couldn\'t fetch machines', reason : err
        return new KDNotificationView title : 'Couldn\'t fetch your VMs'

      callback machines


  addVMTree: ->

    @addSubView section = new KDCustomHTMLView tagName : 'section'

    @machineTree = new JTreeViewController
      type                : 'main-nav'
      treeItemClass       : NavigationItem
      addListsCollapsed   : yes

    # This is temporary, we will create a separate TreeViewController
    # for this and put this logic into there ~ FIXME ~ GG
    @machineTree.dblClick = (nodeView, event)->
      machine = nodeView.getData()
      if machine.status?.state is Machine.State.Running
        @toggle nodeView

    section.addSubView header = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'sidebar-title'
      partial  : 'VMs'

    header.addSubView new KDCustomHTMLView
      tagName  : 'a'
      cssClass : 'buy-vm'
      click    : KD.singletons.computeController
        .bound 'handleNewMachineRequest'

    section.addSubView @machineTree.getView()

    @machineTree.on 'NodeWasAdded', (machineItem) =>

      machineItem.on 'click', @lazyBound 'handleMachineItemClick', machineItem

    if KD.userMachines.length
      @listMachines KD.userMachines
      @updateMachineTree()
    else
      @fetchMachines @bound 'listMachines'


  handleMachineItemClick: (machineItem, event) ->

    machine  = machineItem.getData()
    {status} = machine
    {Building, Running} = Machine.State

    @activityLink?.unsetClass 'selected'

    if event.target.nodeName is 'SPAN'

      if status?.state is Running
        KD.utils.stopDOMEvent event
        KD.singletons.mainView.openMachineModal machine, machineItem
      else return

    else if machineItem.getData().status?.state is Machine.State.Building

      return


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
        href     : KD.utils.groupifyLink '/Activity/Topic/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchFollowedChannels
          limit : limit
        , callback
      countSource: (callback) ->
        KD.remote.api.SocialChannel.fetchFollowedChannelCount {}, callback

    if KD.singletons.mainController.isFeatureDisabled 'channels'
      @sections.channels.hide()


  addConversations: ->

    @addSubView @sections.conversations = new ActivitySideView
      title      : 'Threads'
      cssClass   : 'conversations hidden'
      itemClass  : SidebarPinnedItem
      dataPath   : 'pinnedMessages'
      delegate   : this
      noItemText : 'You didn\'t participate in any conversations yet.'
      headerLink : KD.utils.groupifyLink '/Activity/Post/All'
      dataSource : (callback) ->
        KD.singletons.socialapi.channel.fetchPinnedMessages
          limit : 5
        , callback

    if KD.singletons.mainController.isFeatureDisabled 'threads'
      @sections.conversations.hide()


  addMessages: ->

    limit = 3

    @addSubView @sections.messages = new ActivitySideView
      title      : 'Chat'
      cssClass   : 'messages'
      itemClass  : SidebarMessageItem
      searchClass: ChatSearchModal
      dataPath   : 'privateMessages'
      delegate   : this
      noItemText : "No chat messages yet."
      searchLink : '/Activity/Chat/All'
      limit      : limit
      headerLink : new CustomLinkView
        cssClass : 'add-icon'
        title    : ' '
        href     : KD.utils.groupifyLink '/Activity/Message/New'
      dataSource : (callback) ->
        KD.singletons.socialapi.message.fetchPrivateMessages
          limit  : limit
        , callback
      countSource: (callback) ->
        KD.remote.api.SocialMessage.fetchPrivateMessageCount {}, callback

    if KD.singletons.mainController.isFeatureDisabled 'private-messages'
      @sections.messages.hide()


  addNewWorkspace: (machineItem) ->
    return if @addWorkspaceView

    {machineUId, machineLabel} = machineItem.getData()
    type     = 'new-workspace'
    delegate = machineItem.getDelegate()
    parentId = machineUId
    id       = "#{machineUId}-input"
    data     = { type, machineUId, machineLabel, parentId, id }
    tree     = @machineTree

    @addWorkspaceView = delegate.addItem { type, machineUId, machineLabel }

    @addWorkspaceView.child.once 'KDObjectWillBeDestroyed', =>
      delegate.removeItem @addWorkspaceView
      @addWorkspaceView = null

    @addWorkspaceView.child.input.setFocus()


  createNewWorkspace: (options = {}) ->
    {name, machineUId, rootPath, machineLabel} = options
    {computeController, router } = KD.singletons
    layout = {}

    if not name or not machineUId
      return warn 'Missing options for create new workspace'

    unless rootPath
      rootPath       = "/home/#{KD.nick()}/Workspaces/#{name}"
      emptyWorkspace = yes

    data    = { name, machineUId, machineLabel, rootPath, layout }
    machine = m for m in computeController.machines when m.uid is machineUId
    command = "mkdir -p '#{rootPath}' ; cd '#{rootPath}' ; touch README.md"

    return warn "Machine not found."  unless machine

    callback = =>
      KD.remote.api.JWorkspace.create data, (err, workspace) =>
        return KD.showError "Couldn't create new workspace"  if err

        for nodeData in @machineTree.indexedNodes when nodeData.uid is machine.uid
          parentId = nodeData.id

        view    = @addWorkspaceView
        data    =
          title : workspace.name
          type  : 'workspace'
          href  : "/IDE/#{machine.slug or machine.label}/#{workspace.slug}"
          data  : workspace
          id    : workspace._id
          machineLabel : machineLabel
          parentId: parentId

        if view
          list  = view.getDelegate()
          list.removeItem view  if view
        else
          for key, node of @machineTree.nodes when node.type is 'title'
            list = node.getDelegate()

        @machineTree.addNode data

        KD.userWorkspaces.push workspace

        router.handleRoute data.href

    if emptyWorkspace
      machine.getBaseKite().exec({ command })
      .then  (res) => callback()
      .catch (err) ->
        KD.showError 'Unable to create a new workspace'
    else
      callback()


  updateMachineTree: (callback = noop) ->

    @fetchMachines (machines) =>

      @renderMachines machines, callback


  renderMachines: (machines, callback = noop)->

    jMachines = []
    jMachines.push machine.data for machine in machines

    @machineTree.removeAllNodes()
    @listMachines jMachines

    @selectWorkspace()
    callback()
