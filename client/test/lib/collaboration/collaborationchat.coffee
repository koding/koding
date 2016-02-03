utils                = require '../utils/utils.js'
helpers              = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
assert               = require 'assert'


module.exports =


  before: (browser) ->


    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'

    if hostBrowser
      utils.getUser()

    if utils.suiteHookHasRun 'before'
    then return
    else utils.registerSuiteHook 'before'


  kiсkUserFromSession: (browser) ->

    collaborationHelpers.testKickUser_(browser)


  kickUserAndInviteAgain: (browser) ->

    host                   = utils.getUser no, 0
    participant            = utils.getUser no, 1
    secondUserName         = participant.username
    sharedMachineSelector  = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
    informationModal       = '.kdmodal:not(.env-modal)'

    browser.pause 2500, -> # wait for user.json creation
      if hostBrowser
        collaborationHelpers.startSessionAndInviteUser(browser, host, participant)
        collaborationHelpers.kickUser(browser, participant)
        collaborationHelpers.closeChatPage(browser)
        collaborationHelpers.endSessionFromStatusBar(browser)
        browser.end()
      else
        collaborationHelpers.joinSession(browser, host, participant)
        collaborationHelpers.assertKicked(browser)
        browser.pause 5000
        browser.end()

    hostCallback = ->

      username = participant.username

      collaborationHelpers.inviteUser(browser, username)

    participantCallback = ->

      sharedMachineSelector = '.activity-sidebar .shared-machines .sidebar-machine-box .vm.running'
      browser.waitForElementPresent sharedMachineSelector, 200000

    collaborationHelpers.testKickUser_(browser, hostCallback, participantCallback)
