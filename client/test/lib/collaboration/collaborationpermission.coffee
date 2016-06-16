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
      collaborationHelpers.leaveSessionFromStatusBar(browser)
      browser.end()


    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)


  makePresenterThenRevokeAccess: (browser) ->

    participant             = utils.getUser no, 1
    participantAvatar       = '.IDE-StatusBar .avatars .avatarview'
    participantOnlineAvatar = "#{participantAvatar}.online"
    watchingAvatar          = '.avatars .avatarview.watching'
    makePresenterItem       = '.IDE-StatusBarContextMenu .make-presenter'
    revokePermissionItem    = '.IDE-StatusBarContextMenu .revoke-permission'

    hostCallback = ->

      browser
        .moveToElement            participantAvatar, 5, 5
        .waitForElementVisible    makePresenterItem, 20000
        .click                    makePresenterItem
        .pause                    2000 # wait a bit before revoke
        .waitForElementVisible    watchingAvatar, 20000
        .moveToElement            participantAvatar, 5, 5
        .waitForElementVisible    revokePermissionItem, 20000
        .click                    revokePermissionItem
        .pause                    2000
        .waitForElementNotPresent watchingAvatar, 20000

      collaborationHelpers.waitParticipantLeaveAndEndSession(browser)
      browser.end()


    participantCallback = ->

      browser
        .waitForElementVisible    "#{notificationView}.success", 30000
        .waitForElementVisible    '.plus .icon', 20000
        .waitForElementVisible    "#{notificationView}.error", 30000
        .waitForElementNotVisible '.plus .icon', 20000

      collaborationHelpers.leaveSessionFromStatusBar(browser)
      browser.end()


    collaborationHelpers.initiateCollaborationSession(browser, hostCallback, participantCallback)
