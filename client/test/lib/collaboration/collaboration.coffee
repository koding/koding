helpers = require '../helpers/helpers.js'
collaborationHelpers = require '../helpers/collaborationhelpers.js'
assert  = require 'assert'


module.exports =


  startSession: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    collaborationHelpers.startSession(browser)

    browser.end()


  endSessionFromStatusBar: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    collaborationHelpers.startSession(browser)
    collaborationHelpers.endSessionFromStatusBar(browser)

    browser.end()


  endSessionFromChat: (browser) ->

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    collaborationHelpers.startSession(browser)
    collaborationHelpers.endSessionFromChat(browser)

    browser.end()


  checkThatHostCannotInviteHimself: (browser) ->

    user = helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    collaborationHelpers.startSession(browser)
    collaborationHelpers.inviteUser(browser, user.username, no)

    chatSelecor = "span.profile[href='/#{user.username}']"

    browser
      .pause                     2000
      .waitForElementNotPresent  chatSelecor, 20000
      .end()
