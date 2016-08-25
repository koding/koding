hat = require 'hat'
async = require 'async'

KONFIG = require 'koding-config-manager'
apiErrors = require '../errors'
{ handleUsername } = require '../helpers'

GenericHandler = require './generichandler'


module.exports = class User extends GenericHandler

  # event user_create
  @create = (data, callback = -> ) ->

    # validating req params
    { error, username, email, firstName,
      lastName, suggestedUsername } = @validateDataFor 'create', data

    return callback error  if error

    bongo     = @getBongo()
    { JUser } = @getModels()

    client = null

    queue  = [

      (next) ->
        JUser.one { username }, (err, user) ->
          if err or user
            return next err ? { message: 'user already exists' }
          next()

      (next) ->
        handleUsername username, suggestedUsername, (err, _username) ->
          return next err  if err
          username = _username
          next()

      (next) ->
        context = { group: KONFIG.gitlab.team }
        bongo.fetchClient 1, context, (client_) ->
          return next apiErrors.internalError  if client_.message
          client = client_
          next()

      (next) ->
        password = passwordConfirm = hat()
        userData = {
          email, username, firstName, lastName, password, passwordConfirm
          agree     : 'on'
          groupName : KONFIG.gitlab.team
        }

        # here we don't check if email is in allowed domains
        # because the user who has the api token must be a group admin
        # they should be able to use any email they want for their own team  ~ OK
        options  = { skipAllowedDomainCheck : yes }

        JUser.convert client, userData, options, (err, data) ->
          if err or not data.user
            return next err ? apiErrors.failedToCreateUser
          next null, username

    ]

    async.series queue, callback


  # event user_destroy
  @destroy = (data, callback = -> ) ->

    { JSession, JUser } = @getModels()
    { username, email, name } = data
    bongo     = @getBongo()
    groupName = KONFIG.gitlab.team

    client = null
    queue  = [

      # make sure user exists before trying to unregister
      (next) ->
        JUser.one { username }, (err, user) ->
          if err or not user
            return next err ? { message: 'user not exists' }
          next()

      (next) ->
        JSession.createNewSession { username, groupName }, (err, session) ->
          if err or not session
            return next err ? { message: 'failed to create session' }

          bongo.fetchClient session.clientId, (client_) ->
            client = client_
            next()

      (next) ->
        JUser.unregister client, username, next

    ]

    async.series queue, callback


  # event user_add_to_team
  @add_to_team = (data, callback = -> ) ->
    { project_path_with_namespace
      user_username
      user_email } = data

    # IMPLEMENT ME

    callback { message: 'user add_to_team handler is not implemented' }


  # event user_remove_from_team
  @remove_from_team = (data, callback = -> ) ->
    { project_path_with_namespace
      user_username
      user_email } = data

    # IMPLEMENT ME

    callback { message: 'user remove_from_team handler is not implemented' }


  # event user_add_to_group
  @add_to_group = (data, callback = -> ) ->
    { group_path
      group_access
      user_name
      user_email
      user_username } = data

    # IMPLEMENT ME

    callback { message: 'user add_to_group handler is not implemented' }


  # event user_remove_from_group
  @remove_from_group = (data, callback = -> ) ->
    { group_path
      group_access
      user_name
      user_email
      user_username } = data

    # IMPLEMENT ME

    callback { message: 'user remove_from_group handler is not implemented' }
