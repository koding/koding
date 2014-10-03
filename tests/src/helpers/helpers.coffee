utils    = require '../utils/utils.js'
register = require '../register/register.js'


module.exports =

  doLogin: (browser, user) ->

    browser
      .waitForElementVisible  '[testpath=main-header]', 5000
      .click                  '[testpath=login-link]'
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
      .waitForElementVisible  '.acc-dropdown-icon', 10000
      .click                  '.acc-dropdown-icon'
      .click                  'a[href="/Logout"]'
      .pause                  3000
      .waitForElementVisible  '[testpath=main-header]', 10000 # Assertion


  doRegister: (browser, user) ->
    user    = utils.getUser(yes) unless user
    url     = @getUrl()

    browser
      .url                    @getUrl()
      .waitForElementVisible  '[testpath=main-header]', 10000
      .setValue               'input[name=email]', user.email
      .setValue               'input[name=username]', user.username
      .click                  '.kdbutton.solid.medium'
      .setValue               'input[name=password]', user.password
      .setValue               'input[name=passwordConfirm]', user.password
      .click                  '.kdbutton.solid.green'

    @doLogout browser

    @doLogin browser, user


  getUrl: ->
    return 'http://lvh.me:8090'
