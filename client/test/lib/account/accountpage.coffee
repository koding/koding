utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'

postSelector  = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'
linkSelector  = postSelector + ' .meta a.profile'


module.exports =


  seePostsInAccountPage: (browser) ->

    user = helpers.beginTest(browser)
    post = helpers.postActivity(browser, no)

    postInPageSelector = '[testpath=activity-list] [testpath=ActivityListItemView]:first-child'

    browser
      .waitForElementVisible   linkSelector, 25000
      .click                   linkSelector
      .waitForElementVisible   '.member.content-display', 25000
      .waitForElementVisible   postInPageSelector, 25000
      .assert.containsText     postInPageSelector, post
      .end()


  zoomPhoto: (browser) ->

    user = helpers.beginTest(browser)
    post = helpers.postActivity(browser, no)

    browser
      .waitForElementVisible   linkSelector, 25000
      .click                   linkSelector
      .waitForElementVisible   '.member.content-display', 25000
      .waitForElementVisible   '.own-profile.app-sidebar', 25000
      .waitForElementVisible   '.own-profile.app-sidebar span.avatarview img', 25000
      .click                   '.own-profile.app-sidebar span.avatarview img'
      .pause 2000
      .waitForElementVisible   '.avatar-container.kddraggable .kdmodal-inner span.avatarview', 25000
      .end()
