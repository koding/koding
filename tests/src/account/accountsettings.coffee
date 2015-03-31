utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'


module.exports =

  editFirstName: (browser) ->

    helpers.beginTest(browser)
    inputSelector = '.firstname input.text'

    helpers.changeName(browser, inputSelector, yes)
    browser.end()


  editLastName: (browser) ->

    helpers.beginTest(browser)
    inputSelector = '.lastname input.text'

    helpers.changeName(browser, inputSelector, no)
    browser.end()


  changePassword: (browser) ->

    newPassword           = utils.getPassword()
    inputSelector         = '.password input.text'
    modalSelector         = '.AppModal-form'
    passwordModalSelector = '.kdmodal.kddraggable:not(.AppModal)'
    saveButtonSelector    = '.AppModal--account .button-field button'

    user = helpers.beginTest(browser)
    helpers.openAccountPage(browser)

    browser
      .waitForElementVisible   inputSelector, 20000
      .clearValue              modalSelector + ' input[name=password]'
      .setValue                modalSelector + ' input[name=password]', newPassword
      .clearValue              modalSelector + ' input[name=confirmPassword]'
      .setValue                modalSelector + ' input[name=confirmPassword]', newPassword

      .waitForElementVisible   saveButtonSelector, 20000
      .click                   saveButtonSelector

      .waitForElementVisible   passwordModalSelector , 20000
      .waitForElementVisible   passwordModalSelector + ' input[name=password]', 20000
      .setValue                passwordModalSelector + ' input[name=password]', user.password, =>
        browser
          .click                   passwordModalSelector + ' button[type=submit]'

          .waitForElementVisible   '.kdnotification.main', 20000
          .click                   '.kdmodal-inner .close-icon'

        utils.getUser(yes)
        user.password = newPassword

        helpers.doLogout(browser)
        helpers.doLogin(browser, user)
        browser.end()
