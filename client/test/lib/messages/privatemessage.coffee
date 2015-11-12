helpers = require '../helpers/helpers.js'
assert  = require 'assert'
messagesHelpers = require '../helpers/messageshelpers.js'


module.exports =


  startConversation: (browser) ->

    users = [
      { userName: 'kodingtester', fullName: 'Koding Tester' }
    ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, users)
    browser.end()


  startConversationWithPurpose: (browser) ->

    users = [
      { userName: 'testuser1', fullName: 'Test1 User1' }
    ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, users, 'Hello World!', 'My Purpose')
    browser.end()


  refreshPageAndSeeTheConversationInSidebar: (browser) ->

    users = [
      { userName: 'qatester', fullName: 'QA Tester' }
    ]

    helpers.beginTest(browser)

    isStarted = messagesHelpers.startConversation(browser, users)

    if isStarted then browser.end()
    else
      browser
        .refresh()
        .waitForElementVisible  '.activity-sidebar .messages', 20000
        .assert.containsText    '.activity-sidebar .messages', users[0].fullName  # Assertion
        .end()


  leaveConversation: (browser) ->

    users = [
      { userName: 'kodingtester', fullName: 'Koding Tester' }
    ]

    helpers.beginTest(browser)

    userSelector = ".activity-sidebar .messages .sidebar-message-text [href='/kodingtester']"

    browser.element 'css selector', userSelector, (result) =>
      if result.status is 0
        browser.click userSelector
        messagesHelpers.leaveConversation(browser, users[0])
      else
        messagesHelpers.startConversation(browser, users)
        messagesHelpers.leaveConversation(browser, users[0])

    browser.end()


  startConversationWithMultiplePeople: (browser) ->

    users = [
      { userName: 'testuser2', fullName: 'Test2 User2' }
      { userName: 'testuser3', fullName: 'Test3 User3' }
      { userName: 'testuser4', fullName: 'Test4 User4' }
    ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, users)
    browser.end()

