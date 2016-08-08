helpers              = require '../helpers/helpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
utils                = require '../utils/utils.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'


module.exports =

  before: (browser) -> utils.beforeCollaborationSuite browser

  afterEach: (browser, done) -> utils.afterEachCollaborationTest browser, done

  start: (browser) ->
    sidebarSelector          = '.activity-sidebar .SidebarTeamSection'
    sidebarStackSection      = "#{sidebarSelector} .SidebarStackSection.active"
    vmSelector               = "#{sidebarStackSection} .SidebarMachinesListItem cite"

    hostCallback = ->

      browser.waitForElementVisible vmSelector, 20000
      browser.waitForElementVisible '.SidebarMachinesListItem.Running .SidebarListItem-icon', 30000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()


    participantCallback = ->

      browser.waitForElementVisible '.SidebarMachinesListItem.NotInitialized .SidebarListItem-icon', 20000
      collaborationHelpers.leaveSession(browser)
      browser.end()

    browser.pause 2500, -> # wait for user.json creation
      collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  runCommandOnTerminal: (browser) ->

    host           = utils.getUser no, 0
    hostBrowser    = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    terminalText   = host.teamSlug
    activeTerminal = '.kdtabpaneview.terminal.active'

    hostCallback = ->

      browser.element 'css selector', activeTerminal, (result) ->
        if result.status is 0
          helpers.runCommandOnTerminal(browser, terminalText)
        else
          terminalHelpers.openNewTerminalMenu(browser)
          terminalHelpers.openTerminal(browser)
          helpers.runCommandOnTerminal(browser, terminalText)

        collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
        browser.end()


    participantCallback = ->

      browser
        .waitForElementVisible activeTerminal, 50000
        .waitForTextToContain  activeTerminal, terminalText

      collaborationHelpers.leaveSession(browser)
      browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  openFile: (browser) ->

    host                   = utils.getUser no, 0
    user                   = utils.getUser no, 1
    hostBrowser            = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    paneSelector           = '.kdsplitview-panel.panel-1 .pane-wrapper .application-tab-handle-holder'
    lineWidgetSelector     = '.kdtabpaneview.active .ace-line-widget-'
    participantFileName    = 'python.py'
    participantFileContent = 'Hello World from Python by Koding'
    hostFileName           = 'index.html'
    hostFileContent        = 'Hello World from Html by Koding'
    fileSelector           = "span[title='/home/#{host.username}/.config/python.py']"
    htmlFileSelector       = "span[title='/home/#{host.username}/.config/index.html']"
    markerSelector         = '.ace-line-widget .username'

    hostCallback = ->

      ideHelpers.closeFile(browser, participantFileName, host)
      ideHelpers.closeFile(browser, hostFileName, host)
      browser
        .waitForElementNotPresent  '.kdtabhandle.indexhtml', 20000
        .waitForElementNotPresent  '.kdtabhandle.pythonpy', 20000


      ideHelpers.openFileFromConfigFolder browser, host, hostFileName, hostFileContent
      collaborationHelpers.answerPermissionRequest(browser, yes)
      browser.waitForElementVisible "#{paneSelector} .pythonpy",  60000
      browser
        .waitForElementVisible     markerSelector, 20000
        .assert.containsText       markerSelector, user.username

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.pause 1000
      helpers.deleteFile(browser, fileSelector)
      helpers.deleteFile(browser, htmlFileSelector)

      browser.end()


    participantCallback = ->
      browser.pause 5000
      browser.waitForElementVisible "#{paneSelector} .indexhtml", 60000
      collaborationHelpers.requestPermission(browser, yes)
      ideHelpers.openFileFromConfigFolder browser, host, participantFileName, participantFileContent
      browser.pause 1000, ->
        collaborationHelpers.leaveSession(browser)
        browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback, yes)


  openTerminalWithInvitedUser: (browser) ->

    host         = utils.getUser no, 0
    hostBrowser  = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    paneSelector = '.pane-wrapper .kdsplitview-panel.panel-1'
    terminalTab  = "#{paneSelector} .application-tab-handle-holder .kdtabhandle.terminal.active"
    terminalPane = "#{paneSelector} .kdtabpaneview.terminal.active .terminal-pane"

    commonCallback = ->

      browser
        .waitForElementVisible terminalTab,  35000
        .pause                 6000 # wait for connecting text
        .assert.containsText   terminalPane, host.username


    hostCallback = ->

      collaborationHelpers.answerPermissionRequest(browser, yes)
      commonCallback()
      browser.pause 6000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()

    participantCallback = ->

      collaborationHelpers.requestPermission(browser, yes)
      terminalHelpers.openNewTerminalMenu(browser)
      terminalHelpers.openTerminal(browser)
      commonCallback()

      collaborationHelpers.leaveSession(browser)
      browser.end()


    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)

  openVideoChat: (browser) ->

    hostCallback = ->
      collaborationHelpers.openVideochat browser
      collaborationHelpers.endSessionFromStatusBar(browser)
      browser.end()

    participantCallback = ->
      browser.pause 8000, ->
        browser
          .waitForElementVisible '.kdmodal-content', 40000
          .assert.containsText '.ContentModal.content-modal header > h1', 'Session ended'
          .waitForElementVisible '.ContentModal.content-modal footer .kdbutton', 20000
          .click '.ContentModal.content-modal footer .kdbutton'

      browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  inviteSameUserAndAccept: (browser) ->
    shareModal        = '.Popover-Wrapper'
    acceptButton      = '.SidebarWidget .kdbutton.green'
    filetree          = '.ide-files-tab'
    endButtonSelector = '.IDE-StatusBar .share.active button'

    hostCallback = ->

      browser.pause 20000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()

    participantCallback = ->

      browser.keys([browser.Keys.COMMAND, 't'])
      browser.pause 2000
      browser.getCollabLink browser, (url) ->
        browser
          .url                       url
          .waitForElementVisible     shareModal, 20000
          .waitForElementVisible     acceptButton, 20000
          .click                     acceptButton
          .waitForElementVisible     filetree, 20000
          .waitForElementVisible     endButtonSelector, 20000
          .assert.containsText       endButtonSelector, 'LEAVE SESSION'

        collaborationHelpers.leaveSession(browser)
        browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)
