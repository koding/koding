utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  registerUser: (browser) ->

    helpers.doRegister(browser)

    browser.end()


  registerWithInvalidUsername: (browser) ->

    user = utils.getUser()
    user.username = '{r2d2}'

    helpers.attemptEnterEmailAndUsernameOnRegister(browser, user)
    browser
      .waitForElementVisible    '.validation-error', 20000 # Assertion
      .end()

  registerWithInvalidEmail: (browser) ->

    user = utils.getUser()
    user.email = 'r2d2.kd.io'

    helpers.attemptEnterEmailAndUsernameOnRegister(browser, user)
    browser
      .waitForElementVisible    '.validation-error', 20000 # Assertion
      .end()


  registerWithInvalidPassword: (browser) ->

    user = utils.getUser()
    user.password = '123456'

    helpers.attemptEnterEmailAndUsernameOnRegister(browser, user)
    helpers.attemptEnterPasswordOnRegister(browser, user)

    browser
      .waitForElementVisible    '.kdmodal-inner', 20000 # Assertion
      .end()

