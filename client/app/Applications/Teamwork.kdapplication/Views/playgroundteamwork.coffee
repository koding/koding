class PlaygroundTeamwork extends TeamworkWorkspace

  constructor: (options = {}, data) ->

    super options, data

    @container.setClass options.playground

  handleRun: (panel) ->
    options      = @getOptions()
    {playground} = options
    runConfig    = options.playgroundManifest.run

    return warn "Missing run config for #{playground}."  unless runConfig

    unless runConfig.handler
      return warn "Missing handler for #{playground} run config."

    {handler, command} = runConfig

    if handler is "terminal"
      unless command
        return warn "Missing command for #{playground} run config"

      {path}         = panel.getPaneByName("editor").getActivePaneFileData()
      plainPath      = FSHelper.plainPath path
      command        = command.replace "$ACTIVE_FILE_PATH", """ "#{plainPath}" """
      {paneLauncher} = panel

      if paneLauncher.paneVisibilityState.terminal is no
        paneLauncher.handleLaunch "terminal"

      paneLauncher.terminalPane.runCommand command
    else
      warn "Unimplemented run hanldler for #{playground}"
