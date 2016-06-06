teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
async = require 'async'
stackSelector = null
sidebarhelper  = require '../helpers/sidebarhelpers.js'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'

    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.inviteAndJoinWithUsers browser, users, (result) ->
          next null, result
      (next) ->
        teamsHelpers.createCredential browser, 'aws', 'test credential', no, (res) ->
          next null, res
      (next) ->
        teamsHelpers.createStack browser, (res) ->
          next null, res

      (next) ->
        teamsHelpers.createDefaultStackTemplate browser, (res) ->
          # remove main url from result
          # to get '/Stack-Editor/machineId'
          res = res.substring helpers.getUrl(yes).length
          stackSelector = res
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err


  sidebar: (browser) ->
    queue = [
      (next) ->
        sidebarhelper.redirectMyAccountPage browser, (result) ->
          next null, result
      (next) ->
        sidebarhelper.redirectStackSettingsMenu browser, (result) ->
          next null, result
      (next) ->
        sidebarhelper.redirectDraftStackSettingsMenu browser, (result) ->
          next null, result
      (next) ->
        sidebarhelper.openSettingsMenu browser, (result) ->
          next null, result
    ]

    async.series queue

  after: (browser) ->
    browser.end()
