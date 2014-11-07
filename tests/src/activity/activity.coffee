utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =


  postActivity: (browser) ->

    helpers.postActivity(browser)

    browser.end()


  postComment: (browser) ->

    helpers.postComment(browser)

    browser.end()


  likeActivity: (browser) ->

    user = helpers.beginTest(browser)
    helpers.postActivity(browser, no)
    selector    = activitySelector + ' [testpath=activity-like-link]'
    likeElement = activitySelector + ' .like-summary'

    browser
      .waitForElementVisible selector, 10000
      .click                 selector
      .waitForElementVisible likeElement, 10000
      .assert.containsText   likeElement, user.username + ' liked this.'
      .end()


  editPost: (browser) ->

    helpers.postActivity(browser)

    post = helpers.getFakeText()

    browser
      .waitForElementVisible      activitySelector + ' .settings-menu-wrapper', 10000
      .click                      activitySelector + ' .settings-menu-wrapper'
      .click                      '.kdcontextmenu .edit-post'
      .clearValue                 activitySelector + ' .edit-widget [testpath=ActivityInputView]'
      .setValue                   activitySelector + ' .edit-widget [testpath=ActivityInputView]', post + '\n'
      .pause                      3000
      .assert.containsText activitySelector, post # Assertion
      .end()


  deletePost: (browser) ->

    helpers.postActivity(browser)
    helpers.postActivity(browser, no)

    post = helpers.getFakeText()

    browser
      .waitForElementVisible        activitySelector + ' .settings-menu-wrapper', 10000
      .click                        activitySelector + ' .settings-menu-wrapper'
      .click                        '.kdcontextmenu .delete-post'
      .click                        '.kdmodal-inner .modal-clean-red'
      .pause                        3000, ->
        text = browser.getText activitySelector
        assert.notEqual text, post # Assertion
      .end()


  likeComment: (browser) ->

    helpers.postComment(browser)

    comment         = helpers.getFakeText()
    commentSelector = activitySelector + ' .comment-container .kdlistitemview-comment:first-child'

    browser
      .waitForElementVisible    commentSelector, 3000
      .click                    commentSelector + ' [testpath=activity-like-link]'
      .waitForElementVisible    commentSelector + ' .liked:not(.count)', 10000 # Assertion
      .end()


  editComment: (browser) ->

    helpers.postComment(browser)

    commentSelector = activitySelector + ' .comment-container button.comment-menu'
    post            =  helpers.getFakeText()

    browser
      .waitForElementPresent    commentSelector, 3000
      .click                    commentSelector
      .waitForElementVisible    '.kdcontextmenu .edit-comment', 5000
      .click                    '.kdcontextmenu .edit-comment'
      .clearValue               activitySelector + ' .comment-container .comment-input-widget [testpath=CommentInputView]'
      .setValue                 activitySelector + ' .comment-container .comment-input-widget [testpath=CommentInputView]', post + '\n'
      .pause                    3000
      .assert.containsText      activitySelector + ' .comment-container', post # Assertion
      .end()


  deleteComment: (browser) ->

    helpers.postComment(browser)

    commentSelector = activitySelector + ' .comment-container button.comment-menu'
    post            =  helpers.getFakeText()

    browser
      .waitForElementPresent    commentSelector, 3000
      .click                    commentSelector
      .waitForElementVisible    '.kdcontextmenu .delete-comment', 5000
      .click                    '.kdcontextmenu .delete-comment'
      .click                    '.kdmodal-inner .modal-clean-red'
      .pause                    3000, ->
        text = browser.getText activitySelector + ' .comment-container'
        assert.notEqual text, post # Assertion
      .end()


  cancelCommentDeletion: (browser) ->

    comment = helpers.postComment(browser)

    commentSelector = activitySelector + ' .comment-container button.comment-menu'

    browser
      .waitForElementPresent    commentSelector, 5000
      .click                    commentSelector
      .waitForElementVisible    '.kdcontextmenu .delete-comment', 5000
      .click                    '.kdcontextmenu .delete-comment'
      .click                    '.kdmodal-inner .modal-cancel'
      .waitForElementNotPresent '.kdoverlay', 5000
      .assert.containsText      activitySelector + ' .comment-container', comment # Assertion
      .end()


  searchActivity: (browser) ->

    post     = helpers.postActivity(browser)
    selector = '[testpath=activity-list] [testpath=ActivityListItemView]:first-child'

    browser
      .setValue                 '.kdtabhandlecontainer .search-input', post + '\n'
      .pause                    5000
      .assert.containsText      selector , post # Assertion
      .end()


  showMoreCommentLink: (browser) ->

    helpers.postComment(browser)

    for i in [1..5]
      helpers.postComment(browser, no, no)

    browser
      .refresh()
      .waitForElementVisible  activitySelector + ' .comment-container [testpath=list-previous-link]', 10000
      .end()


  sendHashtagActivity: (browser) ->

    helpers.sendHashtagActivity(browser)
    browser.end()


  topicFollow: (browser) ->

    hashtag = helpers.sendHashtagActivity(browser)
    selector = activitySelector + ' .has-markdown p a:first-child'

    browser
      .waitForElementVisible   selector, 5000
      .click                   selector
      .pause                   3000 # really required
      .assert.containsText     '[testpath=channel-title]', hashtag # Assertion
      .end()


  postLongMessage: (browser) ->

    helpers.beginTest(browser)

    post = ''

    for i in [1..6]

      post += helpers.getFakeText()

    helpers.doPostActivity(browser, post)
    browser.end()

