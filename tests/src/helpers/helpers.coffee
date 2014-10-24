utils    = require '../utils/utils.js'
register = require '../register/register.js'
faker    = require 'faker'

activitySelector = '[testpath=activity-list] section:nth-of-type(1) [testpath=ActivityListItemView]:first-child'

module.exports =

  beginTest: (browser) ->
    url  = @getUrl()
    user = utils.getUser()
    browser.url(url)
    browser.maximizeWindow()

    @doLogin(browser, user)

    browser.execute 'KD.isTesting = true;'

    return user


  doLogin: (browser, user) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 5000
      .click                  '#main-header [testpath=login-link]'
      .waitForElementVisible  '[testpath=login-container]', 5000
      .setValue               '[testpath=login-form-username]', user.username
      .setValue               '[testpath=login-form-password]', user.password
      .click                  '[testpath=login-button]'
      .pause                  5000
      .element                'css selector', '[testpath=main-sidebar]', (result) =>
        if result.status is 0
          console.log 'log in success'

          browser.waitForElementVisible '[testpath=main-sidebar]', 10000 # Assertion
        else
          console.log 'user is not registered yet. registering the user.'

          @doRegister browser, user


  doLogout: (browser) ->

    browser
      .waitForElementVisible  '[testpath=AvatarAreaIconLink]', 10000
      .click                  '[testpath=AvatarAreaIconLink]'
      .click                  '[testpath=logout-link]'
      .pause                  3000
      .waitForElementVisible  '[testpath=main-header]', 10000 # Assertion


  doRegister: (browser, user) ->

    user    = utils.getUser(yes) unless user
    url     = @getUrl()

    browser
      .url                    @getUrl()
      .waitForElementVisible  '[testpath=main-header]', 10000
      .setValue               '[testpath=register-form-email]', user.email
      .setValue               '[testpath=register-form-username]', user.username
      .click                  '[testpath=signup-button]'
      .setValue               '[testpath=password-input]', user.password
      .setValue               '[testpath=confirm-password-input]', user.password
      .click                  '[testpath=register-submit-button]'

    @doLogout browser

    @doLogin browser, user


  postActivity: (browser, shouldBeginTest = yes) ->

    if shouldBeginTest
      @beginTest(browser)

    post = @getFakeText()

    @doPostActivity(browser, post)

    return post


  postComment: (browser, shouldPostActivity = yes, shouldAssert = yes) ->

    if shouldPostActivity
      @postActivity(browser)

    comment = @getFakeText()

    browser
      .click        '[testpath=ActivityListItemView]:first-child [testpath=CommentInputView]'
      .setValue     '[testpath=ActivityListItemView]:first-child [testpath=CommentInputView]', comment + '\n'

    if shouldAssert
      browser
        .pause               6000 # required
        .assert.containsText '[testpath=ActivityListItemView]:first-child .comment-body-container', comment # Assertion

    return comment


  doPostActivity: (browser, post) ->

    browser
      .click                  '[testpath="public-feed-link/Activity/Topic/public"]'
      .waitForElementVisible  '[testpath=ActivityInputView]', 10000
      .click                  '[testpath="ActivityTabHandle-/Activity/Public/Recent"]'
      .click                  '[testpath=ActivityInputView]'
      .setValue               '[testpath=ActivityInputView]', post
      .click                  '[testpath=post-activity-button]'
      .pause                  6000 # required

    browser.assert.containsText '[testpath=ActivityListItemView]:first-child', post # Assertion


  sendHashtagActivity: (browser) ->

    @beginTest(browser)

    paragraph = @getFakeText()
    hashtag   = '#' + paragraph.split(' ')[0]
    post      = paragraph + ' ' + hashtag

    @doPostActivity(browser, post)

    browser.assert.containsText activitySelector + ' .has-markdown p a:first-child', hashtag # Assertion

    return hashtag


  getFakeText: ->
    return faker.Lorem.paragraph().replace /(?:\r\n|\r|\n)/g, ''


  getUrl: ->
    return 'http://lvh.me:8090'
