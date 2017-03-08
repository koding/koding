utils         = require '../utils/utils.js'
helpers       = require '../helpers/helpers.js'
teamsHelpers  = require '../helpers/teamshelpers.js'
myAccountLink = "#{helpers.getUrl(yes)}/Home/my-account"

nameSelector = 'input[name=firstName]'
lastnameSelector = 'input[name=lastName]'
emailSelector = 'input[name=email]'
saveButtonSelector = 'button[type=submit]'
pinSelector = 'input[name=pin]'
passwordSelector = '.kdview.kdtabpaneview.verifypasswordform div.kdview.formline.password div.input-wrapper input.kdinput.text'
notificationText = 'Password successfully changed!'
notMatchingPasswords = 'Passwords did not match'
invalidCurrentPassword = 'Old password did not match our records!'
min8Character  = 'Passwords should be at least 8 characters!'
paragraph = helpers.getFakeText()
notificationSelector = '.kdnotification-title'
confirmEmailButton = '.kdbutton.GenericButton:nth-of-type(2)'
modalSelector = '.kdmodal-content'
updateEmailButton = '.ContentModal.kdmodal.with-form .kdtabpaneview .formline.button-field .kdbutton'
user =  utils.getUser()

module.exports =

  updateFirstName: (browser, callback) ->
    newName            = paragraph.split(' ')[0]
    browser
      .url myAccountLink
      .pause 2000
      .waitForElementVisible   nameSelector, 20000
      .clearValue              nameSelector
      .setValue                nameSelector, newName + '\n'
      .click                   saveButtonSelector
      .waitForElementVisible   '.kdnotification.main', 20000
      .refresh()
      .pause 3000
      .waitForElementVisible   nameSelector, 20000
      .assert.value            nameSelector, newName
      .pause  1000, callback

  updateLastName: (browser, callback) ->
    newLastName        = paragraph.split(' ')[1]
    browser
      .waitForElementVisible   lastnameSelector, 20000
      .clearValue              lastnameSelector
      .setValue                lastnameSelector, newLastName + '\n'
      .click                   saveButtonSelector
      .waitForElementVisible   '.kdnotification.main', 20000
      .refresh()
      .pause 2000
      .waitForElementVisible   lastnameSelector, 20000
      .assert.value            lastnameSelector, newLastName
      .pause  1000, callback


  updateEmailWithInvalidPassword: (browser, callback) ->
    newEmail = 'wrongemail@koding.com'
    browser
      .refresh()
      .waitForElementVisible   emailSelector, 30000
      .clearValue              emailSelector
      .setValue                emailSelector, newEmail + '\n'
      .click                   saveButtonSelector
      .waitForElementVisible   modalSelector, 20000
      .assert.containsText     '.ContentModal.content-modal header > h1', 'Please verify your password'
      .setValue                passwordSelector, '123456'
      .click                   confirmEmailButton
      .waitForElementVisible   notificationSelector, 20000
      .assert.containsText     notificationSelector, 'Current password cannot be confirmed'
      .pause 1000, callback


  updateEmailWithInvalidPin: (browser, callback) ->
    newEmail = 'wrongemail2@koding.com'
    browser
      .refresh()
      .waitForElementVisible   emailSelector, 30000
      .clearValue              emailSelector
      .setValue                emailSelector, newEmail + '\n'
      .click                   saveButtonSelector
      .pause 2000
      .waitForElementVisible   modalSelector, 20000
      .waitForElementVisible   passwordSelector, 30000
      .setValue                passwordSelector, user.password
      .click                   confirmEmailButton
      .waitForElementVisible   modalSelector, 20000
      .waitForElementVisible   pinSelector, 2000
      .setValue                pinSelector, '1234'
      .click                   updateEmailButton
      .waitForElementVisible   notificationSelector, 20000
      .assert.containsText     notificationSelector, 'PIN is not confirmed.'
      .pause  1, callback


  updatePassword: (browser, callback) ->
    currentPassword = user.password
    newPassword     = utils.getPassword()
    browser
      .refresh()
      .waitForElementVisible   emailSelector, 30000
      .scrollToElement '.HomeAppView--section.password'

    helpers.changePasswordHelper browser, newPassword, newPassword + 'test', null, notMatchingPasswords
    helpers.changePasswordHelper browser, newPassword, newPassword, 'invalidpassword', invalidCurrentPassword
    helpers.changePasswordHelper browser, '1234', '1234', user.password, min8Character
    helpers.changePasswordHelper browser, newPassword, newPassword, user.password, notificationText
    browser
      .pause 3000
      .scrollToElement '.HomeAppView--section.profile'
      .scrollToElement '.HomeAppView--section.password'
      .scrollToElement '.HomeAppView--section.security'
      .waitForElementVisible '.HomeAppView--section.sessions', 20000, callback
