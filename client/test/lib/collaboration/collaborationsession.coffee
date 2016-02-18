utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    return if utils.suiteHookHasRun 'before'
    utils.registerSuiteHook 'before'


  rejectInvitation: (browser) ->

    host            = utils.getUser no, 0
    hostBrowser     = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant     = utils.getUser no, 1
    secondUserName  = participant.username
    chatHeads       = ".chat-view .chat-heads .ParticipantHeads [href='/#{participant.username}']"

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser
        collaborationHelpers.startSessionAndInviteUser(browser, host, participant, no)
        browser.waitForElementNotPresent(chatHeads, 60000)
        collaborationHelpers.endSessionFromStatusBar(browser)
        browser.end()
      else
        collaborationHelpers.rejectInvitation(browser)
        browser.pause 5000
        browser.end()


  leaveSessionFromChat: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'Chat')


  leaveSessionFromSidebar: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'Sidebar')


  leaveSessionFromStatusBar: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'StatusBar')


  startReadOnlySession: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1

    if hostBrowser
       collaborationHelpers.startSessionAndInviteUser(browser, host, participant, yes, yes)
       collaborationHelpers.closeChatPage(browser)
       collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
       browser.end()
    else
      collaborationHelpers.joinSession(browser, host, participant)
      collaborationHelpers.closeChatPage(browser)
      browser
        .waitForElementVisible     '.application-page.read-only', 20000
        .waitForElementNotVisible  '.panel-1 .panel-0 .application-tab-handle-holder .plus', 20000
      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()
