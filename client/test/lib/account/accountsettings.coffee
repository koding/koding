utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myAccountLink = "#{helpers.getUrl(yes)}/Home/my-account"

module.exports =

  updateMyAccount: (browser) ->

    nameSelector       = 'input[name=firstName]'
    lastnameSelector   = 'input[name=lastName]'
    emailSelector      = 'input[name=email]'
    saveButtonSelector = 'button[type=submit]'
    passwordSelector   = '.kdview.kdtabpaneview.verifypasswordform div.kdview.formline.password div.input-wrapper input.kdinput.text'

    paragraph          = helpers.getFakeText()
    newName            = paragraph.split(' ')[0]
    newLastName        = paragraph.split(' ')[1]
    newEmail           = newName+newLastName+'@koding.com'

    user = teamsHelpers.loginTeam(browser)
    browser
      .url myAccountLink
      .pause 2000
      .waitForElementVisible   nameSelector, 20000
      .clearValue              nameSelector
      .setValue                nameSelector, newName + '\n'

      .waitForElementVisible   lastnameSelector, 20000
      .clearValue              lastnameSelector
      .setValue                lastnameSelector, newLastName + '\n'
      .pause  3000

      #Updating Email Address will be added
      # .waitForElementVisible   emailSelector, 20000
      # .clearValue              emailSelector
      # .setValue                emailSelector, newName + '\n'
      
      .click                   saveButtonSelector 
      .waitForElementVisible   '.kdmodal.kddraggable', 20000
      .pause 3000

      .waitForElementVisible   '.kdnotification.main', 20000
      .refresh()
      .pause  3000

      .waitForElementVisible   nameSelector, 20000
      .assert.value            nameSelector, newName

      .waitForElementVisible   lastnameSelector, 20000
      .assert.value            lastnameSelector, newLastName
      .pause 2000

      # .waitForElementVisible   emailSelector, 20000
      # .getValue                emailSelector, (result) ->
      #   assert.equal           result.value, newName
    
    notificationText          = 'Password successfully changed!'
    notMatchingPasswords      = 'Passwords did not match'
    invalidCurrentPassword    = 'Old password did not match our records!'
    min8Character             = 'Passwords should be at least 8 characters!'
    
    currentPassword = user.password
    newPassword     = utils.getPassword()
    
    browser
      .scrollToElement '.HomeAppView--section.password'

    helpers.changePasswordHelper browser, newPassword, newPassword+'test', null, notMatchingPasswords
    helpers.changePasswordHelper browser, newPassword, newPassword, 'invalidpassword', invalidCurrentPassword
    helpers.changePasswordHelper browser, '1234', '1234', user.password, min8Character
    helpers.changePasswordHelper browser, newPassword, newPassword, user.password, notificationText
   
    browser 
      .pause 3000
      .scrollToElement '.HomeAppView--section.profile'
      .scrollToElement '.HomeAppView--section.password'
      .scrollToElement '.HomeAppView--section.security'
      .waitForElementVisible '.HomeAppView--section.sessions', 20000
      .end()
