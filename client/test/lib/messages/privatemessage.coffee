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


  startConversationWithPurpose: (browser) ->

    messageUser =
      userName  : 'testuser1'
      fullName  : 'Test1 User1'

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, messageUser, 'Hello World!', 'My Purpose')
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


  leaveConversation: (browser) ->

    messageUser =
      userName  : 'kodingtester'
      fullName  : 'Koding Tester'

    user                            =  helpers.beginTest(browser)
    sidebarMessageUserNameSelector  = ".activity-sidebar .messages .sidebar-message-text [href='/kodingtester']"

    browser.element 'css selector', sidebarMessageUserNameSelector, (result) =>
      if result.status is 0
        browser
          .waitForElementVisible  sidebarMessageUserNameSelector, 20000
          .click                  sidebarMessageUserNameSelector

        messagesHelpers.leaveConversation(browser, messageUser)
      else
        messagesHelpers.startConversation(browser, messageUser)
        messagesHelpers.leaveConversation(browser, messageUser)

    browser.end()


