helpers          = require '../helpers/helpers.js'
activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =

  # searchActivity: (browser) ->

  #   post     = helpers.postActivity(browser)
  #   selector = '[testpath=activity-list] [testpath=ActivityListItemView]:first-child'
  #   word     = post.split(' ')[0]

  #   browser
  #     .setValue                 '.kdtabhandlecontainer .search-input', word + '\n'
  #     .waitForElementVisible    '.kdtabpaneview.search', 25000
  #     .waitForElementVisible    selector, 25000
  #     .pause                    25000
  #     .assert.containsText      selector, word # Assertion
  #     .end()


  showMoreCommentLink: (browser) ->

    helpers.postComment(browser)
    helpers.postComment(browser, no, no)  for i in [1..4]

    browser
      .refresh()
      .pause 2000  # an unfortunate fix for the wsod
      .refresh()
      .waitForElementVisible  "#{activitySelector} [testpath=list-previous-link]", 25000
      .end()


  sendHashtagActivity: (browser) ->

    helpers.sendHashtagActivity(browser)
    browser.end()


  followTopic: (browser) ->

    helpers.doFollowTopic(browser)
    browser.end()


  unfollowTopic: (browser) ->

    hashtag        = helpers.doFollowTopic(browser)
    publicSelector = '#main-sidebar [testpath="public-feed-link/Activity/Topic/public"]'
    topicSelector  = "#main-sidebar [testpath=\"public-feed-link/Activity/Topic/#{hashtag.replace '#', ''}\"]"
    recentSelector = "[testpath=\"ActivityTabHandle-/Activity/Public/Recent\"]"

    browser
      .click                     '[testpath=channel-title] .following'
      .waitForElementNotVisible  topicSelector, 25000
      .waitForElementVisible     publicSelector, 25000
      .click                     publicSelector
      .waitForElementVisible     recentSelector, 25000
      .refresh()
      .pause 2000  # an unfortunate fix for the wsod
      .refresh()
      .waitForElementVisible     publicSelector, 25000
      .assert.elementNotPresent  topicSelector
      .end()


  changeMostLikedMostRecentTab: (browser) ->

    user             = helpers.beginTest()
    postSelector     = "#{activitySelector} .activity-content-wrapper"
    mostLikeSelector = '.kdtabhandlecontainer [testpath="ActivityTabHandle-/Activity/Public/Liked"]'

    post = helpers.likePost(browser, user)

    browser
      .refresh()
      .click                   '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible   '[testpath=ActivityInputView]', 10000
      .waitForElementVisible   mostLikeSelector, 20000
      .click                   mostLikeSelector
      .assert.containsText     '.kdtabpaneview.most-liked', post # Assertion
      .end()

