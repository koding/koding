{argv} = require 'optimist'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")
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
  { clientId }       = session
  { maxAge, secure } = KONFIG.sessionCookie
  # set cookie as pending cookie
  req.pendingCookies or= {}
  req.pendingCookies.clientId = clientId

  res.cookie 'clientId', clientId, { maxAge, secure }

generateFakeClientFromReq = (req, res, callback)->

  {clientId} = req.cookies
  {section} = req.params

  # TODO change this with Team product
  groupName = 'koding'

  # if client id is not set, check for pendingCookies
  if not clientId and req.pendingCookies?.clientId
    clientId = req.pendingCookies.clientId

  generateFakeClient {clientId, groupName, section}, (err, fakeClient, session) ->

    return callback err  if err

    {delegate} = fakeClient.connection

    updateCookie req, res, session

    return callback null, fakeClient


generateFakeClient = (options, callback) ->

  {clientId, groupName, section} = options

  fakeClient    =
    context       :
      group       : 'koding'
      user        : 'guest-1'
    connection    :
      delegate    : null
      groupName   : 'koding'
    impersonating : false


  return callback null, fakeClient  unless clientId

  bongo.models.JSession.fetchSession clientId, (err, response)->

    return handleError err, callback  if err

    {session} = response

    return handleError new Error "Session is not set", callback  unless session

    fetchGroupName { groupName, section }, (err, groupName)->
      return handleError err, callback  if err

      {username} = session

      prepareFakeClient fakeClient, {groupName, session, username}

      return callback null, fakeClient, session


prepareFakeClient = (fakeClient, options) ->
  {groupName, session, username} = options

  {JAccount} = bongo.models
  account = new JAccount
  account.profile = nickname: username
  account.type = 'unregistered'

  fakeClient.sessionToken = session.clientId

  # set username into context
  fakeClient.context or= {}
  fakeClient.context.group = groupName or fakeClient.context.group
  fakeClient.context.user  = session.username or fakeClient.context.user

  # create connection property
  fakeClient.connection or= {}
  fakeClient.connection.delegate  = account or fakeClient.connection.delegate
  fakeClient.connection.groupName = groupName or fakeClient.connection.groupName

  fakeClient.impersonating = session.impersonating or false


module.exports = { generateFakeClient: generateFakeClientFromReq, updateCookie}

