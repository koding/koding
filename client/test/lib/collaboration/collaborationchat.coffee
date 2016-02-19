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


  kiсkUserFromSession: (browser) ->

    collaborationHelpers.testKickUser_(browser)


  kickUserAndInviteAgain: (browser) ->

    host        = utils.getUser no, 0
    participant = utils.getUser no, 1

    hostCallback = ->
      username = participant.username
      collaborationHelpers.inviteUser(browser, username)

    participantCallback = ->
      sharedMachineSelector  = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
      browser.waitForElementPresent  sharedMachineSelector, 200000

    collaborationHelpers.testKickUser_(browser, hostCallback, participantCallback)


  checkChat: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1

    if hostBrowser
      collaborationHelpers.startSessionAndInviteUser(browser, host, participant, yes, no)
      collaborationHelpers.sendMessage(browser)
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()
    else
      collaborationHelpers.joinSession(browser, host, participant)
      collaborationHelpers.sendMessage(browser)
      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()


  leaveSessionInviteSameUserAgain: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1
    participantAvatar = ".avatars .avatarview.online[href='/#{participant.username}']"


    if hostBrowser
      collaborationHelpers.startSessionAndInviteUser(browser, host, participant, yes, no)

      browser.waitForElementNotPresent participantAvatar, 60000

      collaborationHelpers.inviteUser(browser,participant.username)

      browser.pause 3000 # wait for invitation

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()
    else
      collaborationHelpers.joinSession(browser, host, participant)
      collaborationHelpers.leaveSessionFromSidebar(browser)

      browser.waitForElementVisible '.share-modal', 20000

      browser.end()
