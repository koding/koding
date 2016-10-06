KodingError = require '../error'
{ parseClient } = require './utils'
{ Model, secure, ObjectId, signature } = require 'bongo'

module.exports = class JForeignAuth extends Model

  @share()

  @set
    indexes       :
      # WARNING! ~ GG
      # to make this working properly we need a compound index here and since
      # bongo is not supporting them we need to manually define following:
      #
      #   - { username: 1, group: 1, provider: 1, foreignId: 1 } (unique)
      #
      provider    : 'sparse'
      foreignId   : 'sparse'
      group       : 'sparse'
    schema        :
      username    :
        type      : String
        required  : yes
      group       :
        type      : String
        required  : yes
      provider    :
        type      : String
        required  : yes
      foreignId   :
        type      : String
        required  : yes
      foreignData : Object


  @fetchFromSession = (options, callback) ->

    { session, provider } = options
    { foreignAuth } = session

    unless foreignAuth?[provider]?.foreignId
      return callback \
        new KodingError "No foreignAuth:#{provider} info in session"

    { foreignId } = foreignAuth[provider]
    { groupName: group } = session

    @one { provider, foreignId, group }, (err, foreignData) ->
      return callback err   if err
      return callback null  unless foreignData

      JUser = require './user'
      JUser.one { username: foreignData.username }, (err, user) ->
        return callback err  if err
        return callback new KodingError 'User not found'  unless user

        callback null, { user, foreignData }


  @persistOauthInfo = (options, callback) ->

    { sessionToken, group, username } = options

    JSession = require './session'
    JSession.fetchOAuthInfo sessionToken, (err, foreignData) =>
      return callback err   if err
      return callback null  unless foreignData
      return callback null  unless foreignData.session

      { session } = foreignData

      @create { foreignData, group, username }, (err) ->
        return callback err  if err

        JSession.clearOauthInfo session, (err) ->
          return callback err  if err

          response = {}
          { returnUrl } = session
          response.returnUrl = returnUrl  if returnUrl

          return callback null, response


  @create = ({ foreignData, group, username }, callback) ->

    { foreignAuthType: provider } = foreignData
    foreignData   = foreignData.foreignAuth[provider]
    { foreignId } = foreignData

    query     = { group, username, provider }
    options   = { new: yes, upsert: yes }
    operation = {
      $set: {
        foreignData
        foreignId
        username
        provider
        group
      }
    }

    @findAndModify query, null, operation, options, (err, foreignAuth) ->
      callback err, foreignAuth


  @fetchData = (client, callback) ->

    { err, group, username } = parseClient client
    return callback err  if err

    fieldsToCollect = { provider: 1, foreignData: 1 }
    foreignData = {}

    @someData { username, group }, fieldsToCollect, (err, cursor) ->
      return callback err  if err
      return callback null, foreignData  unless cursor

      do iterate = -> cursor.nextObject (err, data) ->
        return callback err  if err

        if data
          foreignData[data.provider] = data.foreignData
          iterate()
        else
          callback null, foreignData
