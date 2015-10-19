utils    = require '../utils/utils.js'
helpers  = require '../helpers/helpers.js'
HUBSPOT  = yes


module.exports =

  loginWithUsername: (browser) ->

    helpers.beginTest(browser)

    browser.end()


  loginWithEmail: (browser) ->

    ourUser = utils.getUser()

    user = {
      username: ourUser.email
      password: ourUser.password
      email   : ourUser.email
    }

    helpers.beginTest(browser, user)
    browser.end()


  loginWithInvalidUsername: (browser) ->

    user = {
      username: 'r2d2'
      password: 'WEEyoh'
    }

    helpers.assertNotLoggedIn(browser, user)
    browser.end()


  loginWithInvalidPassword: (browser) ->

    ourUser = utils.getUser()
    user    = {
      username: ourUser.username
      password: '12312312'
    }

    helpers.assertNotLoggedIn(browser, user)
    browser.end()


  loginFromHomepageSignupForm: (browser) ->

    user = utils.getUser()

    helpers.attemptEnterEmailAndPasswordOnRegister(browser, user)

    browser
      .waitForElementVisible '[testpath=main-sidebar]', 10000 # Assertion
      .end()


  loginFromSignupModal: (browser) ->

    user = utils.getUser()
    url = helpers.getUrl()

    if HUBSPOT
       url = "#{url}/Register"

    browser
      .url(url)
      .maximizeWindow()

    unless HUBSPOT
      browser
        .waitForElementVisible  '[testpath=main-header]', 50000
        .click                  'nav:not(.mobile-menu) [testpath=login-link]'
        .waitForElementVisible  '[testpath=login-container]', 50000
        .click                  '.login-footer .signup-link a.register'

    browser
      .setValue               '.main-part [testpath=register-form-email]', user.email
      .setValue               '.main-part input[name=password]', user.password
      .click                  '.main-part [testpath=signup-button]'
      .waitForElementVisible  '[testpath=main-sidebar]', 10000 # Assertion
      .end()
