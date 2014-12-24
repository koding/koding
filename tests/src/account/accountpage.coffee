utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'
faker   = require 'faker'


module.exports =

  seePostsInAccountPage: (browser) ->

    user = helpers.beginTest(browser)
    post = helpers.postActivity(browser, no)

    postSelector       = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'
    linkSelector       = postSelector + ' .meta a.profile'
    postInPageSelector = '[testpath=activity-list] [testpath=ActivityListItemView]:first-child'

    browser
      .waitForElementVisible   linkSelector, 25000
      .click                   linkSelector
      .waitForElementVisible   '.member.content-display', 25000
      .waitForElementVisible   postInPageSelector, 25000
      .assert.containsText     postInPageSelector, post
      .end()


  editFirstName: (browser) ->

    helpers.beginTest(browser)
    paragraph = helpers.getFakeText()
    inputSelector = '.firstname input.text'

    helpers.changeName(browser, inputSelector, yes)
    browser.end()

