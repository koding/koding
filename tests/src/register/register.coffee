utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  registerUser: (browser) ->

    helpers.doRegister(browser)

    browser.end()


  registerWithInvalidUsername: (browser) ->

    user = utils.getUser(yes)
    user.username = '{r2d2}'

    helpers.attemptEnterEmailAndUsernameOnRegister(browser, user)
    browser
      .waitForElementVisible    '.validation-error', 20000 # Assertion
      .end()

  registerWithInvalidEmail: (browser) ->

    user = utils.getUser(yes)
    user.email = 'r2d2.kd.io'

    helpers.attemptEnterEmailAndUsernameOnRegister(browser, user)
    browser
      .waitForElementVisible    '.validation-error', 20000 # Assertion
      .end()


  registerWithInvalidPassword: (browser) ->

    user = utils.getUser(yes)
    user.password = '123456'

    helpers.attemptEnterEmailAndUsernameOnRegister(browser, user)
    helpers.attemptEnterPasswordOnRegister(browser, user)

    browser
      .waitForElementVisible    '.kdmodal-inner', 20000 # Assertion
      .end()


  # forgotPasswordWwithEmailConfirmation: (browser) ->  #yarim kaldi

  #   user  = helpers.doRegister(browser)

  #   email = user.email

  #   browser.execute 'KD.isTesting = true;'
  #   browser
  #     .waitForElementVisible  '[testpath=main-header]', 50000
  #     .click                  '#main-header [testpath=login-link]'
  #     .waitForElementVisible  '.forgot-link', 50000
  #     .click                  '.forgot-link'
  #     .waitForElementVisible  '.login-input-view', 20000
  #     .setValue               '.login-input-view', email
  #     .click                  '.login-form button'
  #     .end()
