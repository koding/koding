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

    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
    teamsHelpers.editOrDeletePost(browser, yes, no)
    browser.end()


  deletePost: (browser) ->
  
    message = helpers.getFakeText()
  
    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
    teamsHelpers.editOrDeletePost(browser, no, yes)
    browser.end()


  editPostUsingUPkey: (browser) ->
  
    message           = helpers.getFakeText()
    chatInputSelector = '.ChatPaneFooter .ChatInputWidget textarea'
    textSelector      = '.ChatItem .SimpleChatListItem.ChatItem-contentWrapper .ChatListItem-itemBodyContainer'
    editingSelector   = '.SimpleChatListItem.editing .ChatItem-updateMessageForm.visible .ChatInputWidget textarea'
    chatItem          = '.Pane-body .ChatList .ChatItem:nth-of-type(3)'
 
    user = teamsHelpers.loginTeam(browser)
    teamsHelpers.createChannel(browser, user)
    teamsHelpers.sendComment(browser, message)
 
    browser
      .waitForElementVisible  textSelector, 20000
      .setValue               chatInputSelector, browser.Keys.UP_ARROW
      .waitForElementVisible  editingSelector, 20000 
      .clearValue             editingSelector
      .setValue               editingSelector, 'Message after editing' + browser.Keys.ENTER
      .waitForElementVisible  chatItem, 20000
      .pause                  3000 #waiting for text to be changed
      .assert.containsText    chatItem, 'Message after editing'
      .end()