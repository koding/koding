helpers = require '../helpers/helpers.js'
assert  = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =


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


  cancelPostDeletion: (browser) ->

    post                    = helpers.postActivity(browser)
    postSelector            = "#{activitySelector} .activity-content-wrapper"
    settingsWrapperSelector = "#{activitySelector} .settings-menu-wrapper"

    browser
      .waitForElementVisible    settingsWrapperSelector, 25000
      .click                    settingsWrapperSelector
      .waitForElementVisible    '.kdcontextmenu .delete-post', 20000
      .click                    '.kdcontextmenu .delete-post'
      .click                    '.kdmodal-inner .solid.light-gray.medium'
      .waitForElementNotPresent '.kdoverlay', 25000
      .pause 3000
      .assert.containsText      postSelector, post # Assertion
      .end()
