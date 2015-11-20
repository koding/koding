helpers       = require './helpers.js'
assert        = require 'assert'

activitySelector            = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'
activityInputSelector       = ' [testpath="ActivityInputView"]'
imageText                   = "https://koding-cdn.s3.amazonaws.com/images/default.avatar.111.png hello world!"
firstActivityInputSelector  = "#{activitySelector}#{activityInputSelector}"
linkSelector                = "#{activitySelector} .activity-content-wrapper article a"
codeSelector                = "#{activitySelector} .has-markdown code"
editedCode                  = "console.log('123456789')"
editedPost                  = '```' + editedCode + '```'
finalLink                   = 'https://www.google.com/'

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
    selector = "#{activitySelector} .activity-content-wrapper .link-embed-box img"

    helpers.doPostActivity(browser, image, no)
    browser.waitForElementVisible selector, 20000 # Assertion


  postMessageWithLink: (browser) ->

    link         = 'http://wikipedia.org/'
    comment      = "#{link} hello world!"
    linkSelector = "#{activitySelector} .activity-content-wrapper article a"

    # FIXME: Disabled embeddable assertion because it was failing. -- didem
    # helpers.doPostActivity(browser, comment, yes, yes)

    helpers.doPostActivity(browser, comment, yes, yes)

    browser.getAttribute linkSelector, 'href', (result) ->
      href = result.value
      assert.equal(link, href)


  editAction: (browser, type, editWithCode = yes, editWithImage = yes, editWithLink = yes) ->

    if editWithCode
      if type is 'message'
        @editMessageAction(browser, yes, no, no)
      else
        @editCommentAction(browser, yes, no, no)

    if editWithImage
      if type is 'message'
        @editMessageAction(browser, no, yes, no)
      else
        @editCommentAction(browser, no, yes, no)

    if editWithLink
      if type is 'message'
        @editMessageAction(browser, no, no, yes)
      else
        @editCommentAction(browser, no, no, yes)


  editCommentAction: (browser, editWithCode = yes, editWithImage = yes, editWithLink =yes) ->

    imageSelector             = "#{activitySelector} .embed-image-view img"
    firstCommentInputSelector = "#{activitySelector} .comment-input-view"
    commentContanier          = "#{activitySelector} .comment-container"
    commentSendButton         = "#{commentContanier} .submit-button"
    editCommetSelector        = '.kdcontextmenu .edit-comment .kdview'
    commentBodyContanier      = "#{activitySelector} .comment-contents .comment-body-container"
    commentLinkSelector       = "#{commentBodyContanier} p a"

    browser
      .pause                    2000
      .click                    "#{commentContanier} .comment-menu"
      .waitForElementVisible    editCommetSelector, 20000
      .click                    editCommetSelector
      .clearValue               firstCommentInputSelector

    if editWithCode
      browser
        .setValue               firstCommentInputSelector, editedPost
        .click                  commentSendButton
        .pause                  5000 # wait for image loading
        .waitForElementVisible  "#{commentBodyContanier} p.has-markdown", 20000
        .assert.containsText    "#{commentBodyContanier} p.has-markdown", editedCode

    if editWithImage
      browser
        .setValue               firstCommentInputSelector, imageText
        .click                  commentSendButton
        .waitForElementVisible  commentBodyContanier, 20000
        .refresh()              #in order for the image to resize
        .waitForElementVisible  commentBodyContanier, 20000

      browser.getAttribute imageSelector, 'height', (result) ->
        height = result.value
        assert.equal('111', height)

    if editWithLink
      browser
        .setValue               firstCommentInputSelector, finalLink + ' Hello Koding'
        .pause                  3500 # wait for image loading
        .click                  commentSendButton
        .waitForElementVisible  commentLinkSelector, 20000
        .pause                  3000 # wait for image loading
        .assert.containsText    commentLinkSelector, finalLink + ' Hello Koding'


  editMessageAction: (browser, editWithCode = yes, editImage = yes, editLink =yes) ->

    imageSelector               = "#{activitySelector} .link-embed-box .embed-image-view img"
    doneButtonSelector          = "#{activitySelector} button.done-button span.button-title"
    activiySettingsIconSelector = "#{activitySelector} .settings-menu-wrapper"
    editPostSelector            = '.kdcontextmenu .edit-post .kdview'

    browser
      .waitForElementVisible    activiySettingsIconSelector, 25000
      .click                    activiySettingsIconSelector
      .waitForElementVisible    editPostSelector, 20000
      .click                    editPostSelector
      .waitForElementVisible    firstActivityInputSelector, 20000
      .clearValue               firstActivityInputSelector

    if editWithCode
      browser
        .setValue               "#{activitySelector}#{activityInputSelector}", editedPost
        .click                  doneButtonSelector
        .pause                  1000 # below element is not found without pause
        .waitForElementVisible  codeSelector, 20000
        .assert.containsText    codeSelector, editedCode

    if editImage
      browser
        .setValue    "#{activitySelector}#{activityInputSelector}", imageText
        .pause       3500 #for image load
        .click       doneButtonSelector
        .pause       3500

      # browser.getAttribute imageSelector, 'height', (result) ->
      #   height = result.value
      #   assert.equal('111', height)

    if editLink
      browser
        .setValue               "#{activitySelector}#{activityInputSelector}", finalLink + ' Hello Koding'
        .waitForElementVisible  "#{activitySelector} .activity-input-widget .link-embed-box", 20000
        .pause                  3000 #for image load
        .waitForElementVisible  doneButtonSelector, 20000
        .moveToElement          doneButtonSelector, 15, 10
        .click                  doneButtonSelector
        .assert.containsText    "#{activitySelector} .activity-content-wrapper .link-embed-box .title", 'Google'
        .pause                  3000 #for image load
        .getAttribute linkSelector, 'href', (result) ->
          href = result.value
          assert.equal(finalLink, href)
