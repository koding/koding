helpers                = require '../helpers/helpers.js'
credentialsUrl         = "#{helpers.getUrl(yes)}/Home/stacks/credentials"
sectionSelector        = '.kdview.kdtabpaneview.credentials'
credential             = '.kdview.kdlistitemview.kdlistitemview-default.credential-item'
showButton             = "#{credential} .custom-link-view.HomeAppView--link.primary"
removeButton           = "#{credential} .custom-link-view.HomeAppView--link"
closeModal             = '.kdmodal-inner .close-icon.closeModal'
removeCredentialButton = '[testpath=proceed]:nth-of-type(3)'
credentialInfo         = "#{credential} .credential-info"
credentialHeader       = '.kdview.kdtabpaneview.credentials.clearfix.active .HomeAppView--sectionHeader'

module.exports =

  seeCredentials: (browser, callback) ->
    browser
      .url credentialsUrl
      .waitForElementVisible credentialHeader, 20000
      .assert.containsText credentialHeader, 'Credentials'
      .waitForElementVisible sectionSelector, 20000, callback

  seeDetailsCredentials: (browser, callback) ->
    browser
      .pause 5000
      .url credentialsUrl
      .waitForElementVisible sectionSelector, 20000
      .waitForElementVisible showButton, 20000
      .click showButton
      .waitForElementVisible closeModal, 20000
      .click closeModal
      .pause 2000, callback

  removeSingleCredential: (browser, callback) ->
    browser
      .assert.containsText credentialInfo, 'aws2'
      .click removeButton
      .waitForElementVisible '.kdmodal-inner', 20000
      .waitForElementVisible removeCredentialButton, 40000
      .click removeCredentialButton
      .pause 2000
      .waitForElementVisible credential, 20000
      .assert.containsText credentialInfo, 'aws1'
      .pause 2000
      .click removeButton
      .waitForElementVisible removeCredentialButton, 20000
      .click removeCredentialButton
      .pause 2000, callback
