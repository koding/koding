teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
credentialsUrl = "#{helpers.getUrl(yes)}/Home/Stacks/credentials"
async = require 'async'

sectionSelector        = '.kdview.kdtabpaneview.credentials'
credential             = '.kdview.kdlistitemview.kdlistitemview-default.credential-item'
showButton             = "#{credential} .custom-link-view.HomeAppView--link.primary"
removeButton           = "#{credential} .custom-link-view.HomeAppView--link"
closeModal             = '.kdmodal-inner .close-icon.closeModal'
removeCredentialButton = '.kdmodal-inner .kdview.kdmodal-buttons .kdbutton.solid.red.medium.w-loader'
credentialInfo         = "#{credential} .credential-info"


module.exports =

  seeCredentials: (browser, callback) ->
    browser
      .url credentialsUrl
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
      .waitForElementVisible removeCredentialButton, 20000
      .click removeCredentialButton
      .pause 2000
      .waitForElementVisible credential, 20000
      .assert.containsText credentialInfo, 'aws1'
      .pause 2000
      .click removeButton
      .waitForElementVisible removeCredentialButton, 20000
      .click removeCredentialButton
      .pause 2000, callback
