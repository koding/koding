class TeamworkTabView extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @createElements()
    @keysRef    = @workspaceRef.child "keys"
    @indexRef   = @workspaceRef.child "index"
    @requestRef = @workspaceRef.child "request"
    @stateRef   = @workspaceRef.child "state"

    @listenChildRemovedOnKeysRef()
    @listenRequestRef()

    if @amIHost
      @bindRemoteEvents()
    else
      @keysRef.once "value", (snapshot) =>
        data = snapshot.val()
        return unless data

        @keysRefChildAddedCallback value  for key, value of data
        @bindRemoteEvents()

  listenRequestRef: ->
    @requestRef.on "value", (snapshot) =>
      if @amIHost
        request = snapshot.val()
        return unless request

        @createTabFromFirebaseData request
        @requestRef.remove()

  listenPaneDidShow: ->
    @tabView.on "PaneDidShow", (pane) =>
      @stateRef.child(KD.nick()).set pane.getOptions().indexKey

      # need to delay fetching state ref.
      # otherwise clients might be in different tabs.
      KD.utils.wait 600, =>
        @stateRef.once "value", (snapshot) =>
          map = snapshot.val()
          return unless map

          data = {}

          for username, indexKey of map
            data[indexKey] = []  unless data[indexKey]
            jAccount       = @workspace.users[username]
            data[indexKey].push jAccount  if jAccount

          for pane in @tabView.panes
            {indexKey} = pane.getOptions()
            if data[indexKey]
              avatars = data[indexKey].filter (jAccount) ->
                return if jAccount?.profile.nickname is KD.nick() then no else yes
              pane.tabHandle.avatarView?.avatar?.destroy()
              pane.tabHandle.setAccounts avatars
            else
              pane.tabHandle.avatarView?.avatar?.destroy()

  listenChildRemovedOnKeysRef: ->
    @keysRef.on "child_removed", (snapshot) =>
      data = snapshot.val()
      return unless data

      {indexKey} = data
      for pane in @tabView.panes
        if pane?.getOptions().indexKey is indexKey
          @tabView.removePane pane

  bindRemoteEvents: ->
    @listenPaneDidShow()
    @listenIndexRef()
    @listenChildAddedOnKeysRef()

  listenChildAddedOnKeysRef: ->
    @keysRef.on "child_added", (snapshot) =>
      @keysRefChildAddedCallback snapshot.val()

  keysRefChildAddedCallback: (data) ->
    key     = data.indexKey
    {panes} = @tabView
    isExist = yes for pane in panes when pane.getOptions().indexKey is key

    @createTabFromFirebaseData data  unless isExist

  listenIndexRef: ->

    @indexRef.on "value", (snapshot) =>
      data       = snapshot.val()
      {watchMap} = @workspace
      username   = KD.nick()
      return unless data

      if watchMap[username] is "everybody" or watchMap[username] is data.by
        for pane in @tabView.panes
          if pane.getOptions().indexKey is data.indexKey
            index = @tabView.getPaneIndex pane
            @tabView.showPaneByIndex index

  createElements: ->
    @tabHandleHolder = new ApplicationTabHandleHolder delegate: this
    @tabView         = new ApplicationTabView
      delegate                  : this
      lastTabHandleMargin       : 80
      tabHandleContainer        : @tabHandleHolder
      enableMoveTabHandle       : yes
      resizeTabHandles          : no
      closeAppWhenAllTabsClosed : no
      minHandleWidth            : 150
      maxHandleWidth            : 150
      tabHandleClass            : TabHandleWithAvatar

    @tabView.on "PaneAdded", (pane) =>
      pane.getHandle().on "click", =>
        paneOptions = pane.getOptions()
        @workspace.addToHistory
          message    : "$0 switched to #{paneOptions.title}"
          by         : KD.nick()
          data       :
            title    : paneOptions.title
            indexKey : paneOptions.indexKey

        @indexRef.set
          indexKey   : pane.getOptions().indexKey
          by         : KD.nick()

  addNewTab: ->
    @createPlusHandleDropDown()

  createPlusHandleDropDown: ->
    offset        = @tabHandleHolder.plusHandle.$().offset()
    contextMenu   = new JContextMenu
      delegate    : this
      x           : offset.left - 125
      y           : offset.top  + 30
      arrow       :
        placement : "top"
        margin    : -20
    , @getDropdownItems()

    contextMenu.once "ContextMenuItemReceivedClick", ->
      contextMenu.destroy()

  getDropdownItems: ->
    return {
      "Dashboard" :
        separator : yes
        callback  : => @createDashboard()
      "Editor"    :
        callback  : => @handlePaneCreate "editor",   => @createEditor()
      "Terminal"  :
        callback  : => @handlePaneCreate "terminal", => @createTerminal()
      "Browser"   :
        callback  : => @handlePaneCreate "browser",  => @createPreview()
      "Drawing Board":
        callback  : => @handlePaneCreate "drawing",  => @createDrawingBoard()
    }

  handlePaneCreate: (paneType, callback = noop) =>
    if @amIHost
      callback()
    else
      @requestRef.set
        type : paneType
        by   : KD.nick()

    @workspace.addToHistory
      message: "$0 opened a new #{paneType}"
      by     : KD.nick()

  createTabFromFirebaseData: (data) ->
    {sessionKey, indexKey} = data
    switch data.type
      when "dashboard" then @createDashboard()
      when "terminal"  then @createTerminal     sessionKey, indexKey
      when "browser"   then @createPreview      sessionKey, indexKey
      when "drawing"   then @createDrawingBoard sessionKey, indexKey
      when "editor"
        path = data.filePath or "localfile:/untitled.txt"
        file = FSHelper.createFileFromPath path
        @createEditor file, "", sessionKey, indexKey

  createDashboard: ->
    return @tabView.showPane @dashboard  if @dashboard

    @dashboard = new KDTabPaneView
      title    : "Dashboard"
      indexKey : "dashboard"

    dashboard  = new TeamworkDashboard
      delegate : @workspace.getDelegate()

    @appendPane_ @dashboard, dashboard

    @dashboard.once "KDObjectWillBeDestroyed", =>
      @dashboard = null

    if @amIHost
      @keysRef.push
        type     : "dashboard"
        indexKey : "dashboard"

    @registerPaneRemoveListener_ @dashboard

  createDrawingBoard: (sessionKey, indexKey) ->
    indexKey  = indexKey or @createSessionKey()
    pane      = new KDTabPaneView { title: "Drawing Board", indexKey }
    delegate  = @panel
    drawing   = new CollaborativeDrawingPane { delegate, sessionKey }

    @appendPane_ pane, drawing

    if @amIHost
      @keysRef.push
        type       : "drawing"
        sessionKey : drawing.sessionKey
        indexKey   : indexKey

    @registerPaneRemoveListener_ pane

  registerPaneRemoveListener_: (pane) ->
    pane.on "KDObjectWillBeDestroyed", =>
      switch @workspace.hostStatus
        when "unknown", "offline"
          return

      paneIndexKey = pane.getOptions().indexKey

      @keysRef.once "value", (snapshot) =>
        data = snapshot.val()
        return unless data

        for key, value of data
          if value.indexKey is paneIndexKey
            @keysRef.child(key).remove()

  createEditor: (file, content = "", sessionKey, indexKey) ->
    isLocal  = not file
    file     = file or FSHelper.createFileFromPath "localfile:/untitled.txt"
    indexKey = indexKey or @createSessionKey()
    pane     = new KDTabPaneView { title: file.name, indexKey }
    delegate = @getDelegate()
    editor   = new CollaborativeEditorPane { delegate, sessionKey, file, content }

    @appendPane_ pane, editor
    if @amIHost
      @keysRef.push
        type      : "editor"
        sessionKey: editor.sessionKey
        filePath  : file.path
        indexKey  : indexKey

    @registerPaneRemoveListener_ pane

  openFile: (file, content) ->
    @createEditor file, content

  createTerminal: (sessionKey, indexKey) ->
    indexKey = indexKey or @createSessionKey()
    pane     = new KDTabPaneView { title: "Terminal", indexKey }
    klass    = if @isJoinedASession then SharableClientTerminalPane else SharableTerminalPane
    delegate = @getDelegate()
    terminal = new klass { delegate, sessionKey }

    @appendPane_ pane, terminal

    if @amIHost
      terminal.on "WebtermCreated", =>
        @keysRef.push
          type       : "terminal"
          indexKey   : indexKey
          sessionKey :
            key      : terminal.remote.session
            host     : KD.nick()
            vmName   : KD.getSingleton("vmController").defaultVmName

    @registerPaneRemoveListener_ pane

  createPreview: (sessionKey, indexKey) ->
    indexKey = indexKey or @createSessionKey()
    pane     = new KDTabPaneView { title: "Browser", indexKey }
    delegate = @getDelegate()
    browser  = new CollaborativePreviewPane { delegate, sessionKey }

    @appendPane_ pane, browser

    if @amIHost
      @keysRef.push
        type      : "browser"
        sessionKey: browser.sessionKey
        indexKey  : indexKey

    @registerPaneRemoveListener_ pane

  createChat: ->
    pane = new KDTabPaneView title: "Chat"
    chat = new ChatPane
      cssClass    : "full-screen"
      delegate    : @workspace

    @appendPane_ pane, chat

  appendPane_: (pane, childView) ->
    pane.addSubView childView
    @tabView.addPane pane

  viewAppended: ->
    super
    @createDashboard()  if @amIHost

  pistachio: ->
    """
      {{> @tabHandleHolder}}
      {{> @tabView}}
    """

class TabHandleWithAvatar extends KDTabHandleView

  constructor: (options = {}, data) ->

    options.view = new TabHandleAvatarView options

    super options, data

    @avatarView = @getOption "view"

  setTitle: (title) ->
    @avatarView.title.updatePartial title

  setAccounts: (accounts) ->
    @avatarView.setAccounts accounts

class TabHandleAvatarView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-tab-avatar-view"

    super options, data

    @accounts = []

    @addSubView @title = new KDCustomHTMLView
      cssClass   : "tw-tab-avatar-title"
      partial    : "#{options.title}"

  createAvatar: ->
    @avatar      = new AvatarStaticView
      cssClass   : "tw-tab-avatar-img"
      bind       : "mouseenter mouseleave"
      mouseenter : @bound "avatarMouseEnter"
      mouseleave : @bound "avatarMouseLeave"
      size       :
        width    : 20
        height   : 20
    , @accounts.first

    @addSubView @avatar

  avatarMouseLeave: ->
    @avatar.avatarsMenu?.destroy()

  avatarMouseEnter: ->
    return if @accounts.length <= 1

    offset = @avatar.$().offset()
    @avatar.avatarsMenu = new JContextMenu
      menuWidth     : 160
      delegate      : @avatar
      treeItemClass : AvatarContextMenuItem
      x             : offset.left - 106
      y             : offset.top + 27
      arrow         :
        placement   : "top"
        margin      : 108
      lazyLoad      : yes
    , {}

    KD.utils.defer =>
      @accounts.forEach (account) =>
        @avatar.avatarsMenu.treeController.addNode account

  removeAvatar: ->
    @avatar?.destroy()

  setAccounts: (accounts) ->
    @accounts = accounts
    if accounts.length > 0 then @createAvatar() else @removeAvatar()

class AvatarContextMenuItem extends JContextMenuItem

  constructor: (options = {}, data) ->

    super options, data

    @avatar = new AvatarStaticView
      size     :
        width  : 20
        height : 20
      cssClass : "tw-tab-avatar-img-context"
    , @getData()

  pistachio: ->
    """
      {{> @avatar}}
      #{@getData().profile.nickname}
    """
