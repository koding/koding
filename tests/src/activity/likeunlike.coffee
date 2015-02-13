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


  # unlikePost: (browser) ->

  #   user = helpers.beginTest(browser)
  #   helpers.postActivity(browser, no)

  #   selector    = activitySelector + ' [testpath=activity-like-link]'
  #   visibleLike = selector + ':not(.hidden)'
  #   likeElement = activitySelector + ' .like-summary'

  #   browser
  #     .waitForElementVisible    visibleLike, 25000
  #     .click                    visibleLike
  #     .pause                    5000 # required
  #     .waitForElementVisible    selector + '.liked:not(.count)', 25000
  #     .click                    selector + '.liked:not(.count)'
  #     .waitForElementNotVisible likeElement, 25000
  #     .end()


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

    commentSelector     = activitySelector + ' .comment-container .kdlistitemview-comment:first-child'
    likeLinkSelector    = commentSelector + ' [testpath=activity-like-link]:not(.like-count)'
    afterLikeSelector   = likeLinkSelector + '.liked'
    afterUnlikeSelector = commentSelector + ' [testpath=activity-like-link]:not(.liked):first-child'

    browser
      .waitForElementVisible    commentSelector, 25000
      .waitForElementVisible    likeLinkSelector, 25000
      .click                    likeLinkSelector
      .pause                    8000 # wait for latency to make sure really liked on server
      .waitForElementVisible    afterLikeSelector, 25000
      .click                    afterLikeSelector
      .pause                    8000 # wait for latency to make sure really unliked on server
      .waitForElementVisible    afterUnlikeSelector, 25000
      .end()
