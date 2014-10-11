utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'


module.exports =


  postActivity: (browser) ->

    helpers.postActivity(browser)

    browser.end()


  postComment: (browser) ->

    helpers.postComment(browser)

    browser.end()


  likeActivity: (browser) ->

    helpers.postActivity(browser)
    selector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child [testpath=activity-like-link]'

    browser
      .waitForElementVisible selector, 10000
      .click                 selector

    browser.waitForElementVisible selector + '.liked:not(.count)', 10000 # Assertion

    browser.end()
