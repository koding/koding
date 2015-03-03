utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'
assert  = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =


  searchActivity: (browser) ->

    post     = helpers.postActivity(browser)
    selector = '[testpath=activity-list] [testpath=ActivityListItemView]:first-child'
    word     = post.split(' ')[0]

    browser
      .setValue                 '.kdtabhandlecontainer .search-input', word + '\n'
      .waitForElementVisible    '.kdtabpaneview.search', 25000
      .waitForElementVisible    selector, 25000
      .pause                    25000
      .assert.containsText      selector, word # Assertion
      .end()


  showMoreCommentLink: (browser) ->

    helpers.postComment(browser)

    for i in [1..5]
      helpers.postComment(browser, no, no)

    browser
      .refresh()
      .waitForElementVisible  activitySelector + ' .comment-container [testpath=list-previous-link]', 25000
      .end()


  sendHashtagActivity: (browser) ->

    helpers.sendHashtagActivity(browser)
    browser.end()


  followTopic: (browser) ->

    helpers.doFollowTopic(browser)
    browser.end()


  unfollowTopic: (browser) ->

    hashtag    = helpers.doFollowTopic(browser)
    selector   = '.activity-sidebar .followed.topics'
    publicLink = '[testpath="public-feed-link/Activity/Topic/public"]'

    browser
      .click                   '[testpath=channel-title]' + ' .following'
      .waitForElementVisible   publicLink, 25000
      .click                   publicLink
      .refresh()
      .getText selector, (result) =>
        index = result.value.indexOf(hashtag.replace('#', ''))
        assert.equal(index, -1)
        browser.end()
