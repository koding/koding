helpers      = require '../helpers/helpers.js'
utils        = require '../utils/utils.js'
teamsHelpers = require '../helpers/teamshelpers.js'
HUBSPOT      = no


module.exports =


  likePost: (browser) ->

    message = helpers.getFakeText()

    user    = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
    teamsHelpers.likeunlikePost(browser)
    browser.end()


  unlikePost: (browser) ->

    message = helpers.getFakeText()

    user    = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
    teamsHelpers.likeunlikePost(browser, yes)
    browser.end()


  editPost: (browser) ->

    message       = helpers.getFakeText()
    editedmessage = 'Message after editing'
    textSelector  = '.ChatItem .SimpleChatListItem.ChatItem-contentWrapper .ChatListItem-itemBodyContainer'
    chatInput     = '.editing .ChatItem-updateMessageForm .ChatInputWidget textarea'
    menuButton    = '.SimpleChatListItem.ChatItem-contentWrapper:nth-of-type(1) .ButtonWithMenuWrapper button'
    editButton    = '.ButtonWithMenuItemsList li:nth-child(1)'
    editedText    = '.ChatItem .SimpleChatListItem.edited .ChatListItem-itemBodyContainer .ChatItem-contentBody .MessageBody'

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)

    browser
      .waitForElementVisible  textSelector, 20000
      .moveToElement          textSelector, 10, 10
      .waitForElementVisible  menuButton, 20000
      .click                  menuButton
      .waitForElementVisible  editButton, 20000
      .click                  editButton
      .waitForElementVisible  chatInput, 20000
      .clearValue             chatInput
      .setValue               chatInput, editedmessage
      .setValue               chatInput, browser.Keys.ENTER
      .waitForElementVisible  editedText, 20000
      .assert.containsText    editedText, editedmessage
      .end()
