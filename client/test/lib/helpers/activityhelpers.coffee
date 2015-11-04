helpers       = require './helpers.js'
assert        = require 'assert'

activitySelector      = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'
imageText             = "https://koding-cdn.s3.amazonaws.com/images/default.avatar.111.png hello world!"   
linkSelector          = activitySelector + ' .activity-content-wrapper article a'
activityInputSelector = ' [testpath="ActivityInputView"]'
editedCode            = "console.log('123456789')"
editedPost            = '```' + editedCode + '```'
finalLink             = "https://www.google.com/"

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


  editAction: (browser, type, editWithCode = yes, editWithImage = yes, editWithLink = yes) ->

    if editWithCode
      @goToMessagesAndCommentSection(browser)

      if type is 'message'
        @editMessageAction(browser, yes, no, no)
      else
        @editCommentAction(browser, yes, no, no)

    if editWithImage
      @goToMessagesAndCommentSection(browser)

      if type is 'message'
        @editMessageAction(browser, no, yes, no)
      else
        @editCommentAction(browser, no, yes, no)

    if editWithLink
      @goToMessagesAndCommentSection(browser)

      if type is 'message'
        @editMessageAction(browser, no, no, yes)
      else
        @editCommentAction(browser, no, no, yes)


  editCommentAction: (browser, editWithCode = yes, editWithImage = yes, editWithLink =yes) ->

    imageSelector = activitySelector + ' .embed-image-view [width="100%"]'

    browser
      .pause                    2000
      .click                    activitySelector + ' .comment-menu'
      .waitForElementVisible    '.edit-comment .kdview', 2000
      .click                    '.edit-comment .kdview'
      .clearValue               activitySelector + ' .comment-input-view'

    if editWithCode
      browser 
        .setValue               activitySelector + ' .comment-input-view', editedPost
        .click                  activitySelector + ' .submit-button'
        .pause                  5000 # wait for image loading
        .waitForElementVisible  activitySelector + ' .comment-container .listview-wrapper .comment-contents .comment-body-container p', 2000
        .assert.containsText    activitySelector + ' .comment-container .listview-wrapper .comment-contents .comment-body-container p', editedCode

    if editWithImage
      browser
        .setValue               activitySelector + ' .comment-input-view', imageText
        .click                  activitySelector + ' .submit-button'
        .waitForElementVisible  activitySelector + ' .comment-container .listview-wrapper .comment-contents .comment-body-container', 2000
        .refresh()              #in order for the image to resize
        .waitForElementVisible  activitySelector + ' .comment-container .listview-wrapper .comment-contents .comment-body-container', 5000

      browser.getAttribute imageSelector, 'height', (result) ->
        height = result.value
        assert.equal('111', height)

    if editWithLink
      browser
        .setValue               activitySelector + ' .comment-input-view', finalLink
        .pause                  3500 # wait for image loading
        .click                  activitySelector + ' .submit-button'
        .refresh()              #in order for the image thumbnail to regenerate
        .waitForElementVisible  activitySelector + ' .comment-container .listview-wrapper .title', 5000
        .assert.containsText    activitySelector + ' .comment-container .listview-wrapper .title', 'Google'


  editMessageAction: (browser, editWithCode = yes, editImage = yes, editLink =yes) ->

    imageSelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child .link-embed-box .embed-image-view [width="100%"]'

    browser
      .waitForElementVisible    activitySelector + ' .settings-menu-wrapper', 25000
      .click                    activitySelector + ' .settings-menu-wrapper'
      .waitForElementVisible    '.edit-post .kdview', 3000
      .click                    '.edit-post .kdview'
      .waitForElementVisible    activitySelector + ' .done-button', 2000
      .clearValue               activitySelector + activityInputSelector

    if editWithCode
      browser
        .setValue               activitySelector + activityInputSelector, editedPost
        .click                  activitySelector + ' .done-button'
        .pause                  1000 # below element is not found without pause
        .waitForElementVisible  activitySelector + ' .has-markdown code', 2000
        .assert.containsText    activitySelector + ' .has-markdown code', editedCode

    if editImage
      browser
        .setValue               activitySelector + activityInputSelector, imageText
        .pause                  3500 #for image load
        .click                  activitySelector + ' .done-button'
        .pause                  3500 

      browser.getAttribute imageSelector, 'height', (result) ->
        height = result.value
        assert.equal('111', height)

    if editLink
      browser
        .setValue               activitySelector + activityInputSelector, finalLink
        .waitForElementVisible  activitySelector + ' .activity-content-wrapper .edit-widget-wrapper .activity-input-widget .link-embed-box .with-image a[href="https://www.google.com/"]:first-child', 5000
        .click                  activitySelector + ' .done-button'
        .pause                  5000 #for image load
        .assert.containsText    activitySelector + ' .activity-content-wrapper .link-embed-box .title', 'Google'

      browser.getAttribute linkSelector, 'href', (result) ->
        href = result.value
        assert.equal(finalLink, href)


  goToMessagesAndCommentSection: (browser) ->
    browser
      .pause                    2500 # while typing something steals activity input focus
      .click                    '[testpath="public-feed-link/Activity/Topic/public"]'
      .pause                    3000 # for page load
      .waitForElementVisible    '[testpath=ActivityInputView]', 30000
      .click                    '[testpath="ActivityTabHandle-/Activity/Public/Recent"] a'
      .waitForElementVisible    '.most-recent [testpath=activity-list]', 30000

