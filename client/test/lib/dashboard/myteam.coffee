utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myteamhelper = require '../helpers/myteamhelpers.js'
async        = require 'async'
registeredUser = utils.getUser no, 9
host           = utils.getUser no, 0

module.exports =

  before: (browser, done) ->
    registeredUser = utils.getUser no, 5
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = [
      targetUser1
    ]

    queue = [
      (next) ->
        teamsHelpers.loginTeam browser, registeredUser, no, '', (res) ->
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

  teamSettings: (browser) ->
    member = utils.getUser no, 1
    host = utils.getUser()

    queue = [
      (next) ->
        myteamhelper.editTeamName browser, host, (result) ->
          next null, result
      # (next) ->
      #   myteamhelper.uploadAndRemoveLogo browser, host, (result) ->
      #     next null, result
      (next) ->
        myteamhelper.inviteAndJoinToTeam browser, host, (result) ->
          next null, result
      (next) ->
        myteamhelper.seeTeammatesList browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.changeMemberRole browser, host, (result) ->
          next null, result
      (next) ->
        myteamhelper.uploadCSV browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendAlreadyMemberInvite browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendAlreadyAdminInvite browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendInviteToPendingMember browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendNewAdminInvite browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendNewMemberInvite browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendInviteAll browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.sendInviteToRegisteredUser browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.changeTeamName browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.leaveTeam browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.checkAdmin browser, (result) ->
          next null, result

    ]

    async.series queue


  after: (browser) ->
    browser.end()
