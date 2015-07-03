helpers = require '../helpers/helpers.js'
utils   = require '../utils/utils.js'
assert  = require 'assert'
messagesHelpers = require '../helpers/messageshelpers.js'


module.exports =

  before: (browser) ->

    @users = utils.getUser(no, yes).slice 0, 6

    for user in @users
      helpers.beginTest(browser, user)
      helpers.doLogout(browser)


  startConversation: (browser) ->

    users = [ @users[0] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, users)
    browser.end()


  startConversationWithPurpose: (browser) ->

    users = [ @users[1] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, users, 'Hello World!', 'My Purpose')
    browser.end()


  refreshPageAndSeeTheConversationInSidebar: (browser) ->

    users = [ @users[2] ]

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

    users = [ @users[0] ]

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
      @users[3], @users[4], @users[5]
    ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, users)
    browser.end()

