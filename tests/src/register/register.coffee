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

