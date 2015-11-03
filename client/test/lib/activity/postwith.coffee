helpers = require '../helpers/helpers.js'
assert  = require 'assert'
activityHelpers = require '../helpers/activityhelpers.js'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =


  postMessageWithCode: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.postMessageWithCode(browser)
    browser.end()


  editMessageWithCode: (browser) ->
  
    helpers.beginTest(browser)

    activityHelpers.editMessage(browser, yes, no, no)
    browser.end()


  postMessageWithImage: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.postMessageWithImage(browser)
    browser.end()


  editMessageWithImage: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.editMessage(browser, no, yes, no)
    browser.end()


  postMessageWithLink: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.postMessageWithLink(browser)
    browser.end()


  editMessageWithLink: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.editMessage(browser, no, no, yes)
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


  editCommentWithCode: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.editComment(browser, yes, no, no)
    browser.end()


  postCommentWithImage: (browser) ->

    helpers.beginTest(browser)

    image    = 'https://koding-cdn.s3.amazonaws.com/images/default.avatar.333.png'
    comment  = image + ' hello world!'
    post     = helpers.getFakeText()
    selector = activitySelector + ' .comment-contents .link-embed-box a.embed-image-view'

    helpers.doPostActivity(browser, post)
    helpers.doPostComment(browser, comment) # images do not show a preview so we don't pass embeddable flag

    browser.getAttribute selector, 'href', (result) ->
      href = result.value
      assert.equal(image, href)

      browser.end()


  editCommentWithImage: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.editComment(browser, no, yes, no)
    browser.end()


  postCommentWithLink: (browser) ->

    helpers.beginTest(browser)

    post         = helpers.getFakeText()
    link         = 'http://wikipedia.org/'
    linkSelector = activitySelector + ' .comment-contents .comment-body-container .has-markdown a'

    helpers.doPostActivity(browser, post)
    helpers.doPostComment(browser, link, yes, yes)

    browser.getAttribute linkSelector, 'href', (result) ->
      href = result.value
      assert.equal(link, href)

      browser.end()


  editCommentWithLink: (browser) ->

    helpers.beginTest(browser)

    activityHelpers.editComment(browser, no, no, yes)
    browser.end()
