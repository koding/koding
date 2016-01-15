utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
ideHelpers           = require '../helpers/idehelpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
terminalHelpers      = require '../helpers/terminalhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()


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

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1
    chatBox     = '.chat-view'
    chatHeads   = "#{chatBox} .chat-heads .ParticipantHeads [href='/#{participant.username}']"

    if hostBrowser
      collaborationHelpers.startSessionAndInviteUser(browser, host, participant)
      browser.waitForElementNotPresent chatHeads, 50000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()
    else
      collaborationHelpers.joinSession(browser, host, participant)
      collaborationHelpers.closeChatPage(browser)
      collaborationHelpers.leaveSessionFromChat(browser)
      browser.end()


  leaveSessionFromSidebar: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1
    chatBox     = '.chat-view'
    chatHeads   = "#{chatBox} .chat-heads .ParticipantHeads [href='/#{participant.username}']"

    if hostBrowser
      collaborationHelpers.startSessionAndInviteUser(browser, host, participant)
      browser.waitForElementNotPresent chatHeads, 50000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()
    else
      collaborationHelpers.joinSession(browser, host, participant)
      collaborationHelpers.closeChatPage(browser)
      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()
