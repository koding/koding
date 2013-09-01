class CollaborativePanel extends Panel

  constructor: (options = {}, data) ->

    super options, data

    workspace      = @getDelegate()
    panesLength    = @getPaneLengthFromLayoutConfig()
    createdPanes   = []

    @on "NewPaneCreated", (pane) =>
      createdPanes.push pane
      if createdPanes.length is panesLength
        @getDelegate().emit "AllPanesAddedToPanel", @, createdPanes

  createHeaderButtons: ->
    super
    @header.addSubView new KDCustomHTMLView
      cssClass : "users"
      tooltip  :
        title  : "Show Users"
      click    : => @getDelegate().showUsers()

  createHeaderHint: ->
    super
    @header.addSubView new KDCustomHTMLView
      cssClass : "session-key"
      partial  : @getDelegate().sessionKey
      tooltip  :
        title  : "This is your session key, you can share this key with your friends to work together."

  createPane: (paneOptions, targetContainer) ->
    PaneClass = @getPaneClass paneOptions
    paneOptions.sessionKey = @getOptions().sessionKeys[@panes.length]  if @getOptions().sessionKeys
    isJoinedASession       = !!paneOptions.sessionKey and not @getDelegate().amIHost()

    if isJoinedASession
      if paneOptions.type is "terminal"
        PaneClass = SharableClientTerminalPane
      else if paneOptions.type is "finder"
        PaneClass = CollaborativeClientFinderPane

    return warn "Unknown pane class: #{paneOptions.type}"  unless PaneClass
    pane = new PaneClass paneOptions

    @panesByName[paneOptions.name] = pane  if paneOptions.name

    @panes.push pane
    @emit "NewPaneCreated", pane
    return pane

  getPaneLengthFromLayoutConfig: ->
    options = @getOptions()
    length  = 0

    if options.pane then return 1
    else
      for key, value of options.layout.views
        if value.type is "split"
          length += value.views.length
        else length++

      return length

CollaborativePanel::EditorPaneClass        = CollaborativeEditorPane
CollaborativePanel::TerminalPaneClass      = SharableTerminalPane
CollaborativePanel::FinderPaneClass        = CollaborativeFinderPane
CollaborativePanel::TabbedEditorPaneClass  = CollaborativeTabbedEditorPane
CollaborativePanel::PreviewPaneClass       = CollaborativePreviewPane
CollaborativePanel::VideoPaneClass         = VideoPane