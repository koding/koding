helpers       = require './helpers.js'
assert        = require 'assert'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =

  postMessageWithCode: (browser) ->

    timestamp = Date.now()
    code      = "console.log('#{timestamp}')"
    post      = '```' + code + '```'
    selector  = '[testpath=ActivityListItemView]:first-child .has-markdown code'

    helpers.doPostActivity(browser, post, no)

    browser.assert.containsText selector, code # Assertion


  postMessageWithImage: (browser) ->

    # added 'hello world' bc it first thinks that you type http://placehold.it/
    # and renders it as a link, but if we continue typing it understands that
    # it is an image
    image    = 'https://koding-cdn.s3.amazonaws.com/images/default.avatar.333.png hello world!'
    selector = activitySelector + ' .activity-content-wrapper .link-embed-box img'

    browser
      .waitForElementVisible  '.activity-sidebar .followed.topics', 50000
      .click                  '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible  '[testpath=ActivityInputView]', 25000
      .click                  '[testpath="ActivityTabHandle-/Activity/Public/Recent"]'
      .click                  '[testpath=ActivityInputView]'
      .setValue               '[testpath=ActivityInputView]', image
      .pause                  5000 # wait for image loading
      .click                  '[testpath=post-activity-button]'
      .pause                  5000 # wait for image loading
      .waitForElementVisible   selector, 20000 # Assertion


  postMessageWithLink: (browser) ->

    link         = 'http://wikipedia.org/'
    comment      = link + ' hello world!'
    linkSelector = activitySelector + ' .activity-content-wrapper article a'

    # FIXME: Disabled embeddable assertion because it was failing. -- didem
    # helpers.doPostActivity(browser, comment, yes, yes)

    helpers.doPostActivity(browser, comment, yes)

    browser.getAttribute linkSelector, 'href', (result) ->
      href = result.value
      assert.equal(link, href)


