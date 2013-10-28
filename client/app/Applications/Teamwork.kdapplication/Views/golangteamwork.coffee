class GoLangTeamwork extends TeamworkWorkspace

  constructor: (options = {}, data) ->

    super options, data

    @container.setClass "GoLang"

  handleRun: (panel) ->
    panel.paneLauncher.handleLaunch "terminal"
    path = FSHelper.plainPath panel.getPaneByName("editor").getActivePaneFileData().path
    panel.paneLauncher.terminalPane.runCommand "go run \"#{path}\""