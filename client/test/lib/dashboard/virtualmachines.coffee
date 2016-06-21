teamsHelpers          = require '../helpers/teamshelpers.js'
helpers               = require '../helpers/helpers.js'
utils                 = require '../utils/utils.js'
async                 = require 'async'
virtualmachineshelper = require '../helpers/virtualmachineshelpers.js'

module.exports =

  before: (browser, done) ->

    ###
    * we are creating users list here to send invitation and join to team
    * so we will be able to run our test for different kind of member role
    ###
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
        teamsHelpers.buildStack browser, (res) ->
          next null, res
    ]

    async.series queue, (err, result) ->
      done()  unless err


  virtualmachines: (browser) ->

    member = utils.getUser no, 1
    host = utils.getUser()

    queue = [
      (next) ->
        virtualmachineshelper.seeOwnMachinesList browser, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.seeSpecificationOfMachine browser, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.toggleOnOffMachine browser, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.toggleAlwaysOnMachine browser, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.acceptSharedMachine browser, host, member, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.removeAccessFromSharedMachine browser, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.rejectAndAcceptSharedMachine browser, host, member, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.seeConnectedMachinesList browser, (result) ->
          next null, result
      (next) ->
        virtualmachineshelper.seeSharedMachinesList browser, (result) ->
          next null, result
    ]

    async.series queue


  after: (browser) ->
    browser.end()
