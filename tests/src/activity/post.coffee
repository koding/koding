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


  postMessageAndSeeIfItsPostedOnlyOnce: (browser) ->

    post = helpers.getFakeText()

    helpers.postActivity(browser)

    secondPostSelector = '[testpath=activity-list] section:nth-of-type(2) [testpath=ActivityListItemView]:nth-of-type(1) article'
    secondPost = browser.getText secondPostSelector

    assert.notEqual(post, secondPost)

    browser.end()
