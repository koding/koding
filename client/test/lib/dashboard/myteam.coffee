utils        = require '../utils/utils.js'
helpers      = require '../helpers/helpers.js'
teamsHelpers = require '../helpers/teamshelpers.js'
myteamhelper = require '../helpers/myteamhelpers.js'
async        = require 'async'

module.exports =

  before: (browser, done) ->
    targetUser1 = utils.getUser no, 1
    targetUser1.role = 'member'
    users = targetUser1
    teamsHelpers.inviteAndJoinWithUsers browser, [users], (result) ->
      done()

  teamSettings: (browser) ->
    member = utils.getUser no, 1
    host = utils.getUser()

    queue = [
      (next) ->
        myteamhelper.editTeamName browser, host, (result) ->
          next null, result      
      (next) ->
        myteamhelper.inviteAndJoinToTeam browser, host, (result) ->
          next null, result
      (next) ->
        myteamhelper.seeTeammatesList browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.changeMemberRole browser, host, (result) ->
      #     next null, result
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
      # (next) ->
      #   myteamhelper.sendNewInviteFromResendModal browser, (result) ->
      #     next null, result
      (next) ->
        myteamhelper.changeTeamName browser, (result) ->
          next null, result
      (next) ->
        myteamhelper.leaveTeam browser, (result) ->
          next null, result
    ]

    async.series queue


  # after: (browser) ->
  #   browser.end()
