utils = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


expectValidationError = (browser) ->

  browser
    .waitForElementVisible '.validation-error', 20000 # Assertion
    .end()


module.exports =


  registerUserWithGravatarEmail: (browser) ->

    user =
      email    : 'kodingtestuser@gmail.com'
      username : 'kodingtestuser'
      password : 'passwordfortestuser'
      gravatar : yes

    helpers.attemptEnterEmailAndPasswordOnRegister(browser, user)

    browser
      .pause   5000
      .element 'css selector', '[testpath=main-sidebar]', (result) =>

        if result.status is 0
          browser.end()
        else
          helpers.attemptEnterUsernameOnRegister(browser, user)
          helpers.doLogout(browser)
          helpers.doLogin(browser, user)

          browser.end()


  registerUserWithoutGravatarEmail: (browser) ->

    helpers.doRegister(browser)
    browser.end()


  registerWithInvalidUsername: (browser) ->

    user = utils.getUser(yes)
    user.username = '{r2d2}'

    helpers.attemptEnterEmailAndPasswordOnRegister(browser, user)
    helpers.attemptEnterUsernameOnRegister(browser, user)

    expectValidationError(browser)


  registerWithInvalidEmail: (browser) ->

    user = utils.getUser(yes)
    user.email = 'r2d2.kd.io'

    helpers.attemptEnterEmailAndPasswordOnRegister(browser, user)

    expectValidationError(browser)


  registerWithInvalidPassword: (browser) ->

    user = utils.getUser(yes)
    user.password = '123456'

    helpers.attemptEnterEmailAndPasswordOnRegister(browser, user)

    expectValidationError(browser)


  # forgotPasswordWwithEmailConfirmation: (browser) ->  #yarim kaldi

  #   user  = helpers.doRegister(browser)

  #   email = user.email

  #   browser.execute 'KD.isTesting = true;'
  #   browser
  #     .waitForElementVisible  '[testpath=main-header]', 50000
  #     .click                  '.main-header [testpath=login-link]'
  #     .waitForElementVisible  '.forgot-link', 50000
  #     .click                  '.forgot-link'
  #     .waitForElementVisible  '.login-input-view', 20000
  #     .setValue               '.login-input-view', email
  #     .click                  '.login-form button'
  #     .end()
