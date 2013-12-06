class TeamworkTabView extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @createElements()

  createElements: ->
    @tabHandleHolder = new ApplicationTabHandleHolder
      delegate       : this

    @tabView = new ApplicationTabView
      delegate                  : this
      lastTabHandleMargin       : 200
      tabHandleContainer        : @tabHandleHolder
      closeAppWhenAllTabsClosed : no

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
        callback  : => @createEditor()
      "Terminal"  :
        callback  : => @createTerminal()
      "Preview"   :
        callback  : => @createPreview()
      "Chat"      :
        callback  : => @createChat()
    }

  createDashboard: ->
    return @tabView.showPane @dashboard  if @dashboard

    @dashboard = new KDTabPaneView title: "Dashboard"
    dashboard  = new TeamworkDashboard

    @appendPane_ @dashboard, dashboard

    @dashboard.once "KDObjectWillBeDestroyed", =>
      @dashboard = null

  createEditor: ->
    pane   = new KDTabPaneView title: "Editor"
    editor = new CollaborativeEditorPane {
      delegate     : @getDelegate()
      sessionKey   : @sessionKey
      file         : FSHelper.createFileFromPath "localfile:/untitled.txt"
      content      : ""
    }

    @appendPane_ pane, editor

  createTerminal: (pane) ->
    pane         = new KDTabPaneView title: "Terminal"
    klass        = if @isJoinedASession then SharableClientTerminalPane else SharableTerminalPane
    terminal     = new klass
      delegate   : @getDelegate()
      sessionKey : @sessionKey

    @appendPane_ pane, terminal

  createPreview: (pane) ->
    pane    = new KDTabPaneView title: "Preview"
    preview = new CollaborativePreviewPane
      delegate   : @getDelegate()
      sessionKey : @sessionKey

    @appendPane_ pane, preview

  createChat: (pane) ->
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
