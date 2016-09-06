helpers                = require '../helpers/helpers.js'
teamsHelpers           = require '../helpers/teamshelpers.js'
utils                  = require '../utils/utils.js'
async                  = require 'async'
utilitieshelpers       = require '../helpers/utilitieshelpers.js'
kdCliViewGuideButton   = '.HomeAppView--button.primary'
kdCliBrowser           = 'connect-your-machine'
sectionSelector        = '.HomeAppView--section.kd-cli'
kdBtnviewGuideButton   = '.HomeAppView--section.koding-button .HomeAppView--button'
kdbuttonBrowser        = 'koding-button'
chatlioSectionSelector = '.HomeAppView--section.customer-feedback'
chatlioViewGuideButton = "#{chatlioSectionSelector} a[href='https://www.koding.com/docs/chatlio'].custom-link-view.HomeAppView--button"
chatlioBrowser         = 'https://www.koding.com/docs/chatlio'
host = utils.getUser()

module.exports =

  before: (browser, done) ->

    registeredUser = utils.getUser no, 2
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.loginTeam browser, registeredUser, no, null,  (res) ->
          next null, res
      (next) ->
        teamsHelpers.logoutTeam browser, (res) ->
          next null, res
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
    ]

    async.series queue, (err, result) ->
      done()  unless err


  utilities: (browser) ->
    queue = [
      (next) ->
        utilitieshelpers.checkKdCliCodeBlock browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.checkViewGuideButton browser, kdCliViewGuideButton, kdCliBrowser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.enableTryOnKodingButton browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.checkCodeBlock browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.checkViewGuideButton browser, kdBtnviewGuideButton, kdbuttonBrowser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.saveChatlio browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.checkChatlioLink browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.checkViewGuideButton browser, chatlioViewGuideButton, chatlioBrowser, (result) ->
          next null, result
      (next) ->
        teamsHelpers.logoutTeam browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.seeTryOnKodingButton browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.loginToTeamWithRegisteredAccount browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.loginToTeamWithNonRegisteredAccount browser, (result) ->
          next null, result
      (next) ->
        teamsHelpers.logoutTeam browser, (result) ->
          next null, result
      (next) ->
        teamsHelpers.loginToTeam browser, host , no, '', (result) ->
          next null, result
      (next) ->
        utilitieshelpers.disableTryOnKodingButton browser, (result) ->
          next null, result
      (next) ->
        utilitieshelpers.downloadKodingApp browser, (result) ->
          next null, result
    ]

    async.series queue

  after: (browser) ->
    browser.end()
