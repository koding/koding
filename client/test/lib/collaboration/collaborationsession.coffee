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


  leaveSessionFromSidebar: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'Sidebar')


  leaveSessionFromStatusBar: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'StatusBar')


  startReadOnlySession: (browser) ->

    host        = utils.getUser no, 0
    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'
    participant = utils.getUser no, 1


    hostCallback = ->

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()


    participantCallback = ->

      browser
        .waitForElementVisible     '.application-page.read-only', 20000
        .waitForElementNotVisible  '.panel-1 .panel-0 .application-tab-handle-holder .plus', 20000

      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()


    browser.readOnlySession = yes
    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)