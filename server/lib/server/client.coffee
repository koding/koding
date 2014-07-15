{argv} = require 'optimist'
Object.defineProperty global, 'KONFIG',
  value: require('koding-config-manager').load("main.#{argv.c}")
bongo = require './bongo'

handleError = (err, callback) ->
  console.error err
  return callback? err


fetchGroupName = ({ groupName: name, section }, callback)->
  {JName} = bongo.models

  groupName = ""
  # this means it is not a group or profile feed
  # and it means it is koding group
  # it is like Activity -- Develop

  if not name or name[0].toUpperCase() is name[0]
    return callback null, "koding"
  else
    JName.fetchModels "#{name}", (err, { models })->
      return callback if err
      return callback new Error "JName is not found #{name}/#{section}" if not models and model.length < 1

      model = models.first
      modelName = model.bongo_.constructorName
      if modelName is 'JGroup'
        groupName = model.slug
      else
        groupName = "koding"

      callback null, groupName

fetchAccount = (username, callback)->
  bongo.models.JAccount.one {"profile.nickname" : username }, callback

updateCookie = (req, res, session)->
  {clientId} = session
  { maxAge, secure } = KONFIG.sessionCookie
  # set cookie as pending cookie
  req.pendingCookies or= {}
  req.pendingCookies.clientId = clientId

  res.cookie "clientId", clientId, { maxAge, secure }

generateFakeClientFromReq = (req, res, callback)->
  {clientId} = req.cookies
  {name: groupName, section} = req.params
  # if client id is not set, check for pendingCookies
  if not clientId and req.pendingCookies?.clientId
    clientId = req.pendingCookies.clientId

  generateFakeClient { clientId, groupName, section }, (err, fakeClient) ->
    return callback err  if err?
    {delegate} = fakeClient.connection
    return callback null, fakeClient  if delegate?

    bongo.models.JSession.fetchSession {}, (err, {session, account})->
      return callback err  if err?
      return callback {message: "account cannot be created"}  unless account? and session?
      updateCookie req, res, session

      fakeClient.connection.delegate  = account
      fakeClient.connection.groupName = groupName
      fakeClient.context.user         = session.username
      fakeClient.context.group        = groupName

      callback null, fakeClient

generateFakeClient = ({ clientId, groupName, section }, callback) ->

  fakeClient    =
    context     :
      group     : 'koding'
      user      : 'guest-1'
    connection  :
      delegate  : null
      groupName : 'koding'

  return callback null, fakeClient unless clientId?

  bongo.models.JSession.fetchSession clientId, (err, { session })->
    return handleError err, callback if err
    return handleError new Error "Session is not set", callback unless session?

    fetchGroupName { groupName, section }, (err, groupName)->
      return handleError err, callback if err
      fetchAccount session.username, (err, account)->
        return handleError err, callback if err
        return callback null, fakeClient unless account?

        fakeClient.sessionToken = session.clientId

        # set username into context
        fakeClient.context or= {}
        fakeClient.context.group = groupName or fakeClient.context.group
        fakeClient.context.user  = session.username or fakeClient.context.user

        # create connection property
        fakeClient.connection or= {}
        fakeClient.connection.delegate  = account or fakeClient.connection.delegate
        fakeClient.connection.groupName = groupName or fakeClient.connection.groupName

        return callback null, fakeClient

module.exports = { generateFakeClient: generateFakeClientFromReq, updateCookie}

