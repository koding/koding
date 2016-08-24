utils          = require '../utils/utils.js'
teamsHelpers   = require '../helpers/teamshelpers.js'
onboardinghelper  = require '../helpers/onboardinghelpers.js'
async = require 'async'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1

    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()


  dashboard: (browser) ->
    queue = [
      (next) ->
        onboardinghelper.openOnboarding browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.openStackEditor browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.openOnboarding browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.openCredential browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.openOnboarding browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.openMyTeamScreen browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.openOnboarding browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.installKDLink browser, (result) ->
          next null, result
      (next) ->
        teamsHelpers.logoutTeam browser, (result) ->
          next null, result
      (next) ->
        onboardinghelper.onboardingScreenMember browser, (result) ->
          next null, result
    ]

    async.series queue

  after: (browser) ->
    browser.end()
