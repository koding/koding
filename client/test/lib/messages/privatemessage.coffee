helpers = require '../helpers/helpers.js'
assert  = require 'assert'
utils   = require '../utils/utils.js'
messagesHelpers = require '../helpers/messageshelpers.js'


module.exports =


  before: (browser) ->

    @users = utils.getUser(no, -1).slice 1, 8

    for user in @users
      helpers.beginTest(browser, user)
      helpers.doLogout(browser)


  startConversation: (browser) ->

    testUsers = [ @users[0] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, testUsers)
    browser.end()


  startConversationWithPurpose: (browser) ->

    testUsers = [ @users[1] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, testUsers, 'Hello World!', 'My Purpose')
    browser.end()


  refreshPageAndSeeTheConversationInSidebar: (browser) ->

    testUsers = [ @users[2] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, testUsers)

    browser
      .refresh()
      .waitForElementVisible    '.activity-sidebar .messages', 20000
      .waitForElementNotVisible '[testpath=main-sidebar] section.messages .kdloader', 20000
      .assert.containsText      '.activity-sidebar .messages', testUsers[0].username  # Assertion
      .end()


  leaveConversation: (browser) ->

    testUsers       = [ @users[0] ]
    messagesSection = '[testpath=main-sidebar] section.messages'
    messagesLoader  = "#{messagesSection} .kdloader"

    helpers.beginTest(browser)

    userSelector = ".activity-sidebar .messages .sidebar-message-text [href='/" + testUsers[0].username + "']"

    browser
      .waitForElementVisible    messagesSection, 30000
      .waitForElementNotVisible messagesLoader,  30000

    browser.element 'css selector', userSelector, (result) =>
      if result.status is 0
        browser.click userSelector
        messagesHelpers.leaveConversation(browser, testUsers[0])
      else
        messagesHelpers.startConversation(browser, testUsers)
        messagesHelpers.leaveConversation(browser, testUsers[0])

    browser.end()


  startConversationWithMultiplePeople: (browser) ->

    testUsers = [
      @users[3]
      @users[4]
      @users[5]
    ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, testUsers)
    browser.end()


  sendPrivateMessageWithCode: (browser) ->

    messageWithFullCode = "```console.log('123456789')```"
    testUsers           = [ @users[0] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, testUsers, messageWithFullCode)
    browser.end()


  sendPrivateMessageWithLink: (browser) ->

    link      = 'http://wikipedia.org Hello World'
    testUsers = [ @users[1] ]

    helpers.beginTest(browser)

    messagesHelpers.startConversation(browser, testUsers, link)
    browser.end()


  # sendPrivateMessageWithImage: (browser) ->

  #   image     = "https://koding-cdn.s3.amazonaws.com/images/default.avatar.333.png Hello World"
  #   testUsers = [ @users[6] ]

  #   helpers.beginTest(browser)

  #   messagesHelpers.startConversation(browser, testUsers, image)
  #   browser.end()
