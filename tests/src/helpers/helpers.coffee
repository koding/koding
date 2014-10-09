utils    = require '../utils/utils.js'
register = require '../register/register.js'
faker    = require 'faker'


module.exports =

  beginTest: (browser) ->
    url  = @getUrl()
    user = utils.getUser()

    browser.url(url)
    browser.maximizeWindow()

    @doLogin(browser, user)


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


  postActivity: (browser) ->

    post = faker.Lorem.paragraph().replace(/(?:\r\n|\r|\n)/g, '')

    browser
      .waitForElementVisible  '[testpath=ActivityInputView]', 10000
      .click                  '[testpath="ActivityTabHandle-/Activity/Public/Recent"]'
      .click                  '[testpath=ActivityInputView]'
      .setValue               '[testpath=ActivityInputView]', post
      .click                  '[testpath=post-activity-button]'
      .pause                  3000

    browser.assert.containsText('[testpath=ActivityListItemView]:first-child', post)


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


  getUrl: ->
    return 'http://lvh.me:8090'
