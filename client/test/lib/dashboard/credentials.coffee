teamsHelpers = require '../helpers/teamshelpers.js'
helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'
credentialsUrl = "#{helpers.getUrl(yes)}/Home/Stacks/credentials"


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

    teamsHelpers.inviteAndJoinWithUsers browser, [ users ], (result) ->
      teamsHelpers.createCredential browser, 'aws', 'aws1', yes, ->
        teamsHelpers.createCredential browser, 'aws', 'aws2', yes, ->
          done()

