helpers              = require '../helpers/helpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
utils                = require '../utils/utils.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    if utils.suiteHookHasRun 'before'
    then return
    else utils.registerSuiteHook 'before'


  start: (browser) ->

    browser.pause 2500, -> # wait for user.json creation
      collaborationHelpers.initiateCollaborationSession(browser)
      collaborationHelpers.leaveSession(browser)
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)

      browser.end()


  runCommandOnInviteUserTerminal: (browser) ->

    host           = utils.getUser no, 0
    hostBrowser    = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant    = utils.getUser no, 1
    terminalText   = host.teamSlug
    activeTerminal = '.kdtabpaneview.terminal.active'

    collaborationHelpers.initiateCollaborationSession(browser)
    collaborationHelpers.closeChatPage(browser)

    if hostBrowser
      browser.element 'css selector', activeTerminal, (result) ->
        if result.status is 0
          helpers.runCommandOnTerminal(browser, terminalText)
        else
          terminalHelpers.openNewTerminalMenu(browser)
          terminalHelpers.openTerminal(browser)
          helpers.runCommandOnTerminal(browser, terminalText)
    else
      # wait for terminal command appears on participant
      # we couldn't find a better way to avoid this pause
      # because there is no way to be sure when some text
      # is inserted to terminal or we couldn't find a way. - acetgiller
      browser.pause 13000
      browser.assert.containsText activeTerminal, terminalText

    collaborationHelpers.leaveSession(browser)
    collaborationHelpers.waitParticipantLeaveAndEndSession(browser)

    browser.end()


  openFile: (browser) ->

    host                   = utils.getUser no, 0
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant            = utils.getUser no, 1
    paneSelector           = '.kdsplitview-panel.panel-1 .pane-wrapper .application-tab-handle-holder'
    lineWidgetSelector     = ".kdtabpaneview.active .ace-line-widget-"
    participantFileName    = 'python.py'
    participantFileContent = 'Hello World from Python by Koding'

    collaborationHelpers.initiateCollaborationSession(browser)

    collaborationHelpers.closeChatPage(browser)

    if hostBrowser
      ideHelpers.openFileFromWebFolder browser, host

      # wait for participant file opening
      browser.waitForElementVisible "#{paneSelector} .pythonpy",  60000
        # .waitForElementVisible "#{lineWidgetSelector}#{participant.username}", 60000
    else
      # wait for host file opening
      browser.waitForElementVisible "#{paneSelector} .indexhtml", 60000

      # open file in host's vm
      ideHelpers.openFileFromWebFolder browser, host, participantFileName, participantFileContent
      # browser.waitForElementVisible "#{lineWidgetSelector}#{host.username}", 60000

      collaborationHelpers.leaveSession(browser)

    # assert no line widget after participant left
    # browser.waitForElementNotPresent "#{lineWidgetSelector}#{participant.username}", 60000

    collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
    browser.end()


  openTerminalWithInvitedUser: (browser) ->

    host         = utils.getUser no, 0
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant  = utils.getUser no, 1
    paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1'
    terminalTab  = "#{paneSelector} .application-tab-handle-holder .kdtabhandle.terminal.active"
    terminalPane = "#{paneSelector} .kdtabpaneview.terminal.active .terminal-pane"

    collaborationHelpers.initiateCollaborationSession(browser)
    collaborationHelpers.closeChatPage(browser)

    unless hostBrowser
      terminalHelpers.openNewTerminalMenu(browser)
      terminalHelpers.openTerminal(browser)

    browser
      .waitForElementVisible terminalTab,  35000
      .pause                 6000 # wait for connecting text
      .assert.containsText   terminalPane, host.username

    collaborationHelpers.leaveSession(browser)
    collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
    browser.end()
