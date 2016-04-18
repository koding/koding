utils                = require '../utils/utils.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'

notificationView = '.system-notification.ide-warning-view.in'

module.exports =


  before: (browser) -> utils.beforeCollaborationSuite browser

  afterEach: (browser, done) -> utils.afterEachCollaborationTest browser, done


  denyPermissionRequest: (browser) ->

    hostCallback = ->

      collaborationHelpers.answerPermissionRequest(browser, no)
      browser.waitForElementNotPresent notificationView, 20000
      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()


    participantCallback = ->

      collaborationHelpers.requestPermission(browser, no)
      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()


    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  makePresenterThenRevokeAccess: (browser) ->

    participant          = utils.getUser no, 1
    participantAvatar    = ".avatars .avatarview[href='/#{participant.username}']"
    watchingAvatar       = "#{participantAvatar}.watching"
    makePresenterItem    = '.IDE-StatusBarContextMenu .make-presenter'
    revokePermissionItem = '.IDE-StatusBarContextMenu .revoke-permission'

    hostCallback = ->

      browser
        .waitForElementVisible    participantAvatar, 30000
        .moveToElement            participantAvatar, 5, 5
        .waitForElementVisible    makePresenterItem, 20000
        .click                    makePresenterItem
        .waitForElementVisible    watchingAvatar, 20000
        .pause                    2000 # wait a bit before revoke
        .moveToElement            participantAvatar, 5, 5
        .waitForElementVisible    revokePermissionItem, 20000
        .click                    revokePermissionItem
        .waitForElementNotVisible watchingAvatar, 20000

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()


    participantCallback = ->

      browser
        .waitForElementVisible    "#{notificationView}.success", 30000
        .waitForElementVisible    '.plus .icon', 20000
        .waitForElementVisible    "#{notificationView}.error", 30000
        .waitForElementNotVisible '.plus .icon', 20000

      collaborationHelpers.leaveSessionFromSidebar(browser)
      browser.end()


    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)
