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


  likePost: (browser) ->

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


  unlikePost: (browser) ->

    user = helpers.beginTest(browser)
    helpers.postActivity(browser, no)
    selector    = activitySelector + ' [testpath=activity-like-link]'
    likeElement = activitySelector + ' .like-summary'

    browser
      .waitForElementVisible    selector, 10000
      .click                    selector
      .waitForElementVisible    selector, 10000
      .click                    selector
      .waitForElementNotVisible likeElement, 10000
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


  unlikeComment: (browser) ->

    helpers.postComment(browser)

    comment         = helpers.getFakeText()
    commentSelector = activitySelector + ' .comment-container .kdlistitemview-comment:first-child'

    browser
      .waitForElementVisible    commentSelector, 3000
      .click                    commentSelector + ' [testpath=activity-like-link]'
      .waitForElementVisible    commentSelector + ' [testpath=activity-like-link]', 3000
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


  followTopic: (browser) ->

    helpers.doFollowTopic(browser)
    browser.end()


  unfollowTopic: (browser) ->

    hashtag = helpers.doFollowTopic(browser)
    selector = '.activity-sidebar .followed.topics'

    browser
      .waitForElementVisible   '[testpath=channel-title]' + ' .following', 2000
      .click                   '[testpath=channel-title]' + ' .following'
      .waitForElementVisible   '[testpath="public-feed-link/Activity/Topic/public"]', 2000
      .click                   '[testpath="public-feed-link/Activity/Topic/public"]'
      .refresh()
      .pause 2000 # reguired

    browser.getText selector
    assert.notEqual(hashtag)
    browser.end()


  postLongMessage: (browser) ->

    helpers.beginTest(browser)

    post = ''

    for i in [1..6]

      post += helpers.getFakeText()

    helpers.doPostActivity(browser, post)
    browser.end()


  postLongComment: (browser) ->

    helpers.beginTest(browser)
    post = helpers.getFakeText()
    helpers.doPostActivity(browser, post)
    comment = ''

    for i in [1..6]

      comment += helpers.getFakeText()

    helpers.doPostComment(browser, comment)
    browser.end()


  postMessageWithCode: (browser) ->

    helpers.beginTest(browser)

    timestamp = Date.now()
    code      = "console.log(#{timestamp})"
    post      = '```' + code + '```'
    selector  = '[testpath=ActivityListItemView]:first-child .has-markdown code'

    helpers.doPostActivity(browser, post, no)

    browser
      .assert.containsText selector, code # Assertion
      .end()


  postMessageWithImage: (browser) ->

    helpers.beginTest(browser)

    image = 'http://placehold.it/200x100'

    browser
      .click                  '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible  '[testpath=ActivityInputView]', 10000
      .click                  '[testpath="ActivityTabHandle-/Activity/Public/Recent"]'
      .click                  '[testpath=ActivityInputView]'
      .setValue               '[testpath=ActivityInputView]', image
      .click                  '[testpath=post-activity-button]'
      .pause                  6000 # required

    selector = activitySelector + ' .activity-content-wrapper .embed-image-view img'

    browser
      .waitForElementVisible selector, image # Assertion
      .end()


  postMessageWithLink: (browser) ->

    helpers.beginTest(browser)

    link = 'http://nightwatchjs.org/' # last '/' is the trick!
    linkSelector = activitySelector + ' .activity-content-wrapper article a'

    helpers.doPostActivity(browser, link)

    browser.getAttribute linkSelector, 'href', (result) ->
      href = result.value
      assert.equal(link, href)

    browser.end()


  postMessageAndSeeIfItsPostedOnlyOnce: (browser) ->

    post = helpers.getFakeText()

    helpers.postActivity(browser)

    secondPostSelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:nth-of-type(2) article'
    secondPost = browser.getText secondPostSelector

    assert.notEqual(post, secondPost)

    browser.end()


  postCommentWithCode: (browser) ->

    helpers.beginTest(browser)

    post      = helpers.getFakeText()
    timestamp = Date.now()
    code      = "console.log(#{timestamp})"
    comment   = '```' + code + '```'
    selector  = '[testpath=ActivityListItemView]:first-child .comment-contents .has-markdown code'

    helpers.doPostActivity(browser, post)
    helpers.doPostComment(browser, comment, no)

    browser
      .pause 2000
      .assert.containsText selector, code # Assertion
      .end()


  postCommentWithImage: (browser) ->

    helpers.beginTest(browser)

    post     = helpers.getFakeText()
    image    = 'http://placehold.it/200x100'
    selector = activitySelector + ' .comment-contents .comment-body-container .has-markdown a'

    helpers.doPostActivity(browser, post)
    helpers.doPostComment(browser, image)

    browser
      .assert.containsText selector, image # Assertion
      .end()


  postCommentWithLink: (browser) ->

    helpers.beginTest(browser)

    post     = helpers.getFakeText()
    link = 'http://nightwatchjs.org/' # last '/' is the trick!
    linkSelector = activitySelector + ' .comment-contents .comment-body-container .has-markdown a'

    helpers.doPostActivity(browser, post)
    helpers.doPostComment(browser, link)

    browser.getAttribute linkSelector, 'href', (result) ->
      href = result.value
      assert.equal(link, href)

    browser.end()