helpers = require '../helpers/helpers.js'
assert  = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =


  editPost: (browser) ->

    helpers.postActivity(browser)

    post = helpers.getFakeText()

    browser
      .waitForElementVisible activitySelector + ' .settings-menu-wrapper', 25000
      .click                 activitySelector + ' .settings-menu-wrapper'
      .click                 '.kdcontextmenu .edit-post'
      .clearValue            activitySelector + ' .edit-widget [testpath=ActivityInputView]'
      .setValue              activitySelector + ' .edit-widget [testpath=ActivityInputView]', post
      .click                 activitySelector + ' .done-button'
      .pause                 20000
      .assert.containsText   activitySelector, post # Assertion
      .end()


  deletePost: (browser) ->

    helpers.postActivity(browser)
    helpers.postActivity(browser, no)

    post = helpers.getFakeText()

    browser
      .waitForElementVisible        activitySelector + ' .settings-menu-wrapper', 25000
      .click                        activitySelector + ' .settings-menu-wrapper'
      .click                        '.kdcontextmenu .delete-post'
      .click                        '.kdmodal-inner .solid.red.medium'
      .pause                        20000, ->
        text = browser.getText activitySelector
        assert.notEqual text, post # Assertion
      .end()


  editComment: (browser) ->

    helpers.postComment(browser)

    commentSelector = activitySelector + ' .comment-container button.comment-menu'
    post            =  helpers.getFakeText()

    browser
      .waitForElementPresent    commentSelector, 25000
      .click                    commentSelector
      .waitForElementVisible    '.kdcontextmenu .edit-comment', 25000
      .click                    '.kdcontextmenu .edit-comment'
      .clearValue               activitySelector + ' .comment-container .comment-input-widget [testpath=CommentInputView]'
      .setValue                 activitySelector + ' .comment-container .comment-input-widget [testpath=CommentInputView]', post
      .click                    activitySelector + ' .edit-comment-box .submit-button'
      .pause                    20000
      .assert.containsText      activitySelector + ' .comment-container', post # Assertion
      .end()


  deleteComment: (browser) ->

    helpers.postComment(browser)

    commentSelector = activitySelector + ' .comment-container button.comment-menu'
    post            =  helpers.getFakeText()

    browser
      .waitForElementPresent    commentSelector, 25000
      .click                    commentSelector
      .waitForElementVisible    '.kdcontextmenu .delete-comment', 25000
      .click                    '.kdcontextmenu .delete-comment'
      .click                    '.kdmodal-inner .solid.red.medium'
      .pause                    20000, ->
        text = browser.getText activitySelector + ' .comment-container'
        assert.notEqual text, post # Assertion
      .end()


  cancelCommentDeletion: (browser) ->

    comment         = helpers.postComment(browser)
    commentSelector = activitySelector + ' .comment-container button.comment-menu'

    browser
      .waitForElementPresent    commentSelector, 25000
      .click                    commentSelector
      .waitForElementVisible    '.kdcontextmenu .delete-comment', 25000
      .click                    '.kdcontextmenu .delete-comment'
      .click                    '.kdmodal-inner .solid.light-gray.medium'
      .waitForElementNotPresent '.kdoverlay', 25000
      .assert.containsText      activitySelector + ' .comment-container', comment # Assertion
      .end()
