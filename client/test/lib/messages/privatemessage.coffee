helpers = require '../helpers/helpers.js'
assert  = require 'assert'
messagesHelpers = require '../helpers/messageshelpers.js'


module.exports =


  startConversation: (browser) ->

    messageUser =
      userName  : 'kodingtester'
      fullName  : 'Koding Tester'

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, messageUser)
    browser.end()


  refreshPageAndSeeTheConversationInSidebar: (browser) ->

    messageUser =
      userName  : 'qatester'
      fullName  : 'QA Tester'

    helpers.beginTest(browser)

    isStarted = messagesHelpers.startConversation(browser, messageUser)

    if isStarted then browser.end()
    else
      browser
        .refresh()
        .waitForElementVisible  '.activity-sidebar .messages', 20000
        .assert.containsText    '.activity-sidebar .messages', messageUser.fullName  # Assertion
        .end()
