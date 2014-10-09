utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  activityPost: (browser) ->

    helpers.beginTest(browser)

    browser.click '[testpath=public-feed-link]'

    helpers.postActivity(browser)

    browser.end()
