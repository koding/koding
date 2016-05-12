teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
credentialsUrl = "#{helpers.getUrl(yes)}/Home/Stacks/credentials"
async = require 'async'

module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users =
      targetUser1

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, [ users ], (result) ->
          next null, result
      (next) ->
        teamsHelpers.createCredential browser, 'aws', 'aws1', yes, (res) ->
          next null, res
      (next) ->
        teamsHelpers.createCredential browser, 'aws', 'aws2', yes, (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err


  credentials: (browser) ->

    sectionSelector = '.kdview.kdtabpaneview.credentials'

    browser
      .url credentialsUrl
      .waitForElementVisible sectionSelector, 20000

    sectionSelector = '.kdview.kdtabpaneview.credentials'
    credential = '.kdview.kdlistitemview.kdlistitemview-default.credential-item'
    showButton = "#{credential} .custom-link-view.HomeAppView--link.primary"
    removeButton = "#{credential} .custom-link-view.HomeAppView--link"
    closeModal = '.kdmodal-inner .close-icon.closeModal'
    removeCredentialButton = '.kdmodal-inner .kdview.kdmodal-buttons .kdbutton.solid.red.medium.w-loader'
    credentialInfo = "#{credential} .credential-info"

    browser
      .pause 5000
      .url credentialsUrl
      .waitForElementVisible sectionSelector, 20000
      .waitForElementVisible showButton, 20000
      .click showButton
      .waitForElementVisible closeModal, 20000
      .click closeModal
      .pause 2000
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
      .pause 2000
      .end()
