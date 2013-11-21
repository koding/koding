class PlaygroundTeamwork extends TeamworkWorkspace

  constructor: (options = {}, data) ->

    super options, data

    @on "PanelCreated", =>
      @getActivePanel().header.unsetClass "teamwork"

    @on "ContentIsReady", =>
      return unless @amIHost()
      manifest = @getOptions().playgroundManifest
      {prerequisite, initialState} = manifest
      if prerequisite
        if prerequisite.type is "sh"
          if initialState
          then @doPrerequisite prerequisite.command, => @setUpInitialState initialState
          else @doPrerequisite prerequisite.command
        else
          warn "Unhandled prerequisite type."
      else if initialState
        @setUpInitialState initialState

  handleRun: (panel) ->
    options      = @getOptions()
    {playground} = options
    runConfig    = options.playgroundManifest.run

    return warn "Missing run config for #{playground}."  unless runConfig

    {handler, command} = runConfig
    {paneLauncher}     = panel

    if not handler or not command
      return warn "Missing parameter for #{playground} run config. You must pass a handler and a command"

    if handler is "terminal"
      {path}    = panel.getPaneByName("editor").getActivePaneFileData()
      plainPath = FSHelper.plainPath path
      command   = command.replace "$ACTIVE_FILE_PATH", """ "#{plainPath}" """
      if paneLauncher.paneVisibilityState.terminal is no
        paneLauncher.handleLaunch "terminal"
      paneLauncher.terminalPane.runCommand command
    else if handler is "preview"
      @handlePreview command
    else
      warn "Unimplemented run hanldler for #{playground}"

  doPrerequisite: (command, callback = noop) ->
    return warn "no command passed for prerequisite"  unless command
    KD.getSingleton("vmController").run command, (err, res) =>
      return warn err  if err
      callback()

  setUpInitialState: (initialState) ->
    if initialState.preview
      @handlePreview initialState.preview.url

    if initialState.editor
      @openFiles initialState.editor.files

  handlePreview: (url) ->
    {paneLauncher} = @getActivePanel()
    url            = url.replace "$USERNAME", @getHost()

    if paneLauncher.paneVisibilityState.preview is no
      paneLauncher.handleLaunch "preview"
    paneLauncher.previewPane.openUrl url

  openFiles: (files) ->
    editor = @getActivePanel().getPaneByName "editor"

    for path in files
      filePath = "/home/#{KD.nick()}/Web/Teamwork/#{@getOptions().playground}/#{path.replace /^.\//, ''}"
      file     = FSHelper.createFileFromPath filePath

      file.fetchContents (err, contents) =>
        editor.openFile file, contents
