utils                = require '../utils/utils.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'


module.exports =

  before: (browser) -> utils.beforeCollaborationSuite browser

  afterEach: (browser, done) -> utils.afterEachCollaborationTest browser, done

  leaveSessionFromSidebar: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'Sidebar')


  leaveSessionFromStatusBar: (browser) ->

    collaborationHelpers.testLeaveSessionFrom_(browser, 'StatusBar')


  startReadOnlySession: (browser) ->

    hostBrowser = process.env.__NIGHTWATCH_ENV_KEY is 'host_1'


    hostCallback = ->
      browser.pause 3000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()


    participantCallback = ->

      browser
        .waitForElementVisible     '.application-page.read-only', 20000
        .waitForElementNotVisible  '.panel-1 .panel-0 .application-tab-handle-holder .plus', 20000

      collaborationHelpers.leaveSessionFromStatusBar(browser)
      browser.pause 3000
      browser.end()


    browser.readOnlySession = yes
    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)
