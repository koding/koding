utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    return if utils.suiteHookHasRun 'before'
    utils.registerSuiteHook 'before'


  checkIfInvitedUserCanEditFilesOtherUserVm: (browser) ->

    host               = utils.getUser no, 0
    hostBrowser        = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant        = utils.getUser no, 1
    hostFakeText       = host.fakeText.split(' ')
    fileName           = hostFakeText[0]
    fileSlug           = fileName.replace '.', ''
    tabSelector        = ".kdtabhandle.#{fileSlug}"
    editorSelector     = ".kdtabpaneview.#{fileSlug} .ace_content"
    hostContent        = hostFakeText[1]
    participantContent = participant.fakeText.split(' ')[0]

    hostCallback = ->

      helpers.createFile(browser, host, null, null, fileName)
      ideHelpers.openFile(browser, host, fileName)
      ideHelpers.setTextToEditor(browser, hostContent)
      browser.waitForTextToContain(editorSelector, participantContent)
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()

    participantCallback = ->

      browser
        .waitForElementPresent tabSelector, 50000 # Assertion
        .waitForElementVisible editorSelector, 20000
        .waitForTextToContain  editorSelector, hostContent
        .pause 3000

      ideHelpers.setTextToEditor(browser, participantContent)

      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  checkIfInvitedUserCanSeeExistingOpenIDETabs: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1
    pyContent   = 'Hello World from Python by Koding'

    hostCallback = ->

      helpers.beginTest browser, host
      helpers.waitForVMRunning browser
      ideHelpers.closeAllTabs(browser)

      ideHelpers.openFileFromWebFolder(browser, host, 'index.html')
      ideHelpers.openFileFromWebFolder(browser, host, 'python.py', pyContent)
      terminalHelpers.openNewTerminalMenu(browser)
      terminalHelpers.openTerminal(browser)

      collaborationHelpers.startSessionAndInviteUser_(browser, host, participant, yes)

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()

    participantCallback = ->

      collaborationHelpers.joinSession(browser, host, participant)

      browser
        .waitForElementVisible  '.kdtabhandle.indexhtml', 50000
        .waitForElementVisible  '.kdtabhandle.pythonpy', 20000
        .waitForElementVisible  '.kdtabhandle.terminal', 20000

      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()

    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)









