utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'


module.exports =


  likePost: (browser) ->

    user = helpers.beginTest(browser)
    helpers.postActivity(browser, no)
    selector    = activitySelector + ' [testpath=activity-like-link]'
    likeElement = activitySelector + ' .like-summary'

    browser
      .waitForElementVisible selector, 25000
      .click                 selector
      .waitForElementVisible likeElement, 25000
      .assert.containsText   likeElement, user.username + ' liked this.'
      .end()


  unlikePost: (browser) ->

    user = helpers.beginTest(browser)
    helpers.postActivity(browser, no)
    selector    = activitySelector + ' [testpath=activity-like-link]'
    likeElement = activitySelector + ' .like-summary'

    browser
      .waitForElementVisible    selector, 25000
      .click                    selector
      .waitForElementVisible    selector + '.liked', 25000
      .click                    selector + '.liked'
      .waitForElementNotVisible likeElement, 25000
      .end()


  likeComment: (browser) ->

    helpers.postComment(browser)

    comment         = helpers.getFakeText()
    commentSelector = activitySelector + ' .comment-container .kdlistitemview-comment:first-child'

    browser
      .waitForElementVisible    commentSelector, 25000
      .click                    commentSelector + ' [testpath=activity-like-link]'
      .waitForElementVisible    commentSelector + ' .liked:not(.count)', 25000 # Assertion
      .end()


  unlikeComment: (browser) ->

    helpers.postComment(browser)

    comment         = helpers.getFakeText()
    commentSelector = activitySelector + ' .comment-container .kdlistitemview-comment:first-child'

    browser
      .waitForElementVisible    commentSelector, 25000
      .click                    commentSelector + ' [testpath=activity-like-link]'
      .waitForElementVisible    commentSelector + ' [testpath=activity-like-link]', 25000
      .click                    commentSelector + ' [testpath=activity-like-link]'
      .waitForElementVisible    commentSelector + ' .liked:not(.count)', 25000 # Assertion
      .end()
