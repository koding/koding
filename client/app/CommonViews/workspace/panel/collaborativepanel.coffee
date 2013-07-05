class CollaborativePanel extends Panel

  constructor: (options = {}, data) ->

    super options, data

    workspace      = @getDelegate()
    panesLength    = @getOptions().panes.length
    createadPanes  = []

    @on "NewPaneCreated", (pane) =>
      createadPanes.push pane

      if createadPanes.length is panesLength
        @getDelegate().emit "AllPanesAddedToPanel", @, createadPanes

    log "i've created new panes with these keys", @getOptions().sessionKeys

  createPane: (paneOptions, targetContainer) ->
    PaneClass              = @getPaneClass paneOptions.type
    paneOptions.delegate   = @
    paneOptions.sessionKey = @getOptions().sessionKeys[@panes.length]  if @getOptions().sessionKeys
    isJoinedASession       = !!paneOptions.sessionKey and not @amIHost paneOptions.sessionKey

    if isJoinedASession then log "#{KD.nick()} is joined a session"
    else log "#{KD.nick()} created a session"

    if isJoinedASession
      if paneOptions.type is "terminal"
        PaneClass = CollaborativeClientTerminalPane
      else if paneOptions.type is "finder"
        PaneClass = CollaborativeClientFinderPane

    return warn "Unknown pane class #{paneOptions.type}"  unless PaneClass
    pane = new PaneClass paneOptions

    targetContainer.addSubView pane
    @panes.push pane
    @emit "NewPaneCreated", pane

  amIHost: (sessionKey) ->
    return  no unless sessionKey
    [sessionOwner] = sessionKey.split ":"
    return sessionOwner == KD.nick()

CollaborativePanel::EditorPaneClass        = CollaborativeEditorPane
CollaborativePanel::TerminalPaneClass      = CollaborativeTerminalPane
CollaborativePanel::FinderPaneClass        = CollaborativeFinderPane
CollaborativePanel::TabbedEditorPaneClass  = CollaborativeTabbedEditorPane
CollaborativePanel::VideoPaneClass         = VideoPane
CollaborativePanel::PreviewPaneClass       = PreviewPane