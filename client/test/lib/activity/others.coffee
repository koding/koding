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

    helpers.beginTest(browser)

    helpers.sendHashtagActivity(browser)
    browser.end()


  searchTopicInChannelList: (browser) ->

    helpers.beginTest(browser)

    titleSelector  = '.activity-sidebar .followed .sidebar-title'
    plusSelector   = "#{titleSelector} .add-icon"
    modalSelector  = '.kdmodal-inner .kdmodal-content'
    searchSelector = "#{modalSelector} input.search-input"
    loaderSelector = "#{modalSelector} .lazy-loader"

    hashtag = helpers.sendHashtagActivity(browser)

    browser
      .waitForElementVisible     titleSelector, 20000
      .moveToElement             titleSelector, 5, 10
      .waitForElementVisible     plusSelector, 20000
      .click                     plusSelector
      .waitForElementVisible     '.topic-search', 20000
      .waitForElementVisible     searchSelector, 20000
      .waitForElementNotVisible  loaderSelector, 25000
      .setValue                  searchSelector, hashtag + '\n'
      .pause 3000
      .waitForElementVisible     ".listview-wrapper [testpath=\"public-feed-link/Activity/Topic/#{hashtag.replace '#', ''}\"]", 20000 # Assertion
      .end()


  followTopic: (browser) ->

    helpers.beginTest(browser)

    helpers.doFollowTopic(browser)
    browser.end()


  unfollowTopic: (browser) ->

    helpers.beginTest(browser)

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

    user             = helpers.beginTest(browser)
    postSelector     = "#{activitySelector} .activity-content-wrapper"
    mostLikeSelector = '.kdtabhandlecontainer [testpath="ActivityTabHandle-/Activity/Public/Liked"]'
    mostLikedPostSelector = '.most-liked [testpath=ActivityListItemView]'

    post = helpers.likePost(browser, user)

    browser
      .refresh()
      .waitForElementVisible   '[testpath=ActivityListItemView]', 20000
      .click                   '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible   '[testpath=ActivityInputView]', 10000
      .waitForElementVisible   mostLikeSelector, 20000
      .click                   mostLikeSelector
      .waitForElementVisible   mostLikedPostSelector, 20000
      .assert.containsText     '.kdtabpaneview.most-liked', post # Assertion
      .end()


  switchBetweenChannels: (browser) ->

    helpers.beginTest(browser)

    firstHashtag  = helpers.doFollowTopic(browser)
    secondHashtag = helpers.doFollowTopic(browser)

    firstHashtag  = firstHashtag.replace '#', ''
    secondHashtag = secondHashtag.replace '#', ''

    firstHashtagSelector  = ".followed.topics [testpath='public-feed-link/Activity/Topic/#{firstHashtag}']"
    secondHashtagSelector = ".followed.topics [testpath='public-feed-link/Activity/Topic/#{secondHashtag}']"

    firstHashtagPage  = "#content-page-activity .topic-#{firstHashtag}.topic-pane"
    secondHashtagPage = "#content-page-activity .topic-#{secondHashtag}.topic-pane"

    browser
      .waitForElementVisible  firstHashtagSelector, 20000
      .click                  firstHashtagSelector
      .waitForElementVisible  firstHashtagPage, 20000
      .assert.containsText    firstHashtagPage, firstHashtag # Assertion

      .waitForElementVisible  secondHashtagSelector, 20000
      .click                  secondHashtagSelector
      .waitForElementVisible  secondHashtagPage, 20000
      .assert.containsText    secondHashtagPage, secondHashtag # Assertion
      .end()
