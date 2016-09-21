jraphical = require 'jraphical'
KodingError = require '../error'
{ parseClient } = require './utils'

module.exports = class JForeignAuth extends jraphical.Module

  { secure, ObjectId, signature } = require 'bongo'

  @share()

  @set
    indexes       :
      provider    : 'sparse'
      foreignId   : 'sparse'
      group       : 'sparse'
    sharedEvents  :
      static      : []
      instance    : []
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


  @fetchFromSession = (session, provider, callback) ->

    { foreignAuth } = session

    unless foreignAuth?[provider]?.foreignId
      return callback \
        new KodingError "No foreignAuth:#{provider} info in session"

    { foreignId } = foreignAuth[provider]
    { groupName: group } = session

    @one { provider, foreignId, group }, callback


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

    { foreignAuthType } = foreignData
    foreignData = foreignData.foreignAuth[foreignAuthType]
    foreignAuth = new JForeignAuth {
      provider  : foreignAuthType
      foreignId : foreignData.foreignId
      foreignData
      username
      group
    }

    foreignAuth.save (err) ->
      callback err, foreignAuth


  @fetchData = (client, callback) ->

    { err, group, username } = parseClient client
    return callback err  if err

    fieldsToCollect = { provider: 1, foreignData: 1 }
    foreignData = {}

    @someData { username, group }, fieldsToCollect, (err, cursor) ->
      return callback err  if err
      return callback null, foreignData  unless cursor

      cursor.nextObject (err, data) ->
        return callback err  if err

        if data
        then foreignData[data.provider] = data.foreignData
        else callback null, foreignData
