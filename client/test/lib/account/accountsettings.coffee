utils   = require '../utils/utils.js'
helpers = require '../helpers/helpers.js'

changePasswordHelper = (browser, newPassword1, newPassword2, currentPassword, notificationText, callback) ->

  inputSelector         = '.password input.text'
  modalSelector         = '.AppModal-form'
  passwordModalSelector = '.kdmodal.kddraggable:not(.AppModal)'
  saveButtonSelector    = '.AppModal--account .button-field button'

  user = helpers.beginTest(browser)
  helpers.openAccountPage(browser)

  if not currentPassword
    currentPassword = user.password

  browser
    .waitForElementVisible   inputSelector, 20000
    .clearValue              modalSelector + ' input[name=password]'
    .setValue                modalSelector + ' input[name=password]', newPassword1
    .clearValue              modalSelector + ' input[name=confirmPassword]'
    .setValue                modalSelector + ' input[name=confirmPassword]', newPassword2
    .waitForElementVisible   saveButtonSelector, 20000
    .click                   saveButtonSelector

  if newPassword1 is newPassword2
    browser
      .waitForElementVisible   passwordModalSelector , 20000
      .waitForElementVisible   passwordModalSelector + ' input[name=password]', 20000
      .setValue                passwordModalSelector + ' input[name=password]', currentPassword, =>
        browser
          .click                   passwordModalSelector + ' button[type=submit]'
          .waitForElementVisible   '.kdnotification.main', 20000
          .assert.containsText     '.kdnotification.main', notificationText # Assertion
          .click                   '.kdmodal-inner .close-icon'

          callback(user) if callback
  else
    browser
      .waitForElementVisible   '.kdnotification.main', 20000
      .assert.containsText     '.kdnotification.main', notificationText # Assertion


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


  tryToChangePasswordWithNotMatchingPasswords: (browser) ->

    notificationText = 'Passwords did not match'

    changePasswordHelper(browser, 'koding', 'kodingtest', null, notificationText)
    browser.end()


  tryToChangePasswordWithInvalidCurrentPassword: (browser) ->

    newPassword      = utils.getPassword()
    notificationText = 'Current password cannot be confirmed'

    changePasswordHelper(browser, newPassword, newPassword, 'invalidpassword', notificationText)
    browser.end()


  changePassword: (browser) ->

    fn = (user) ->
      utils.getUser(yes)
      user.password = newPassword

      helpers.doLogout(browser)
      helpers.doLogin(browser, user)
      browser.end()

    newPassword      = utils.getPassword()
    notificationText = 'Your account information is updated.'

    changePasswordHelper(browser, newPassword, newPassword, null, notificationText, fn)
