getNick = require 'app/util/nick'
_ = require 'lodash'

loadCollaborationFile = (manager, id, callback) ->
  manager.once 'FileLoaded', (doc) ->
    manager.setRealtimeDoc doc
    manager.isReady = yes
    callback()
  manager.getFile id

createCollaborationFile = (manager, id, callback) ->
  manager.once 'FileCreated', (file) ->
    callback file
  manager.createFile id

isSessionActive = (manager, title, callback) ->
  manager.once 'FileQueryFinished', (file) ->
    if file.result.items.length > 0
    then callback yes, file.result.items[0]
    else callback no
  manager.fetchFileByTitle title

getFileIdentifier = (id) -> "#{getNick()}.#{id}"

getTargetUser = (participants, field, predicateValue) ->
  targetIndex = null
  targetUser  = null
  participants = participants.asArray()  if participants.asArray?
  for p, index in participants when p?[field] is predicateValue
    targetIndex = index
    targetUser  = p.nickname
    break

  return { targetUser, targetIndex }

getReferences = (manager, channelId, initialSnapshot) ->
  nickname          = getNick()
  watchMapName      = "#{nickname}WatchMap"
  snapshotName      = "#{nickname}Snapshot"
  defaultPermission = { default: 'edit' }

  refs =
    participants      : getFromManager manager, 'participants', 'list', []
    changes           : getFromManager manager, 'changes', 'list', []
    permissions       : getFromManager manager, 'permissions', 'map', {}
    broadcastMessages : getFromManager manager, 'broadcastMessages', 'list', []
    pingTime          : getFromManager manager, 'pingTime', 'list', []
    watchMap          : getFromManager manager, watchMapName, 'map', {}
    snapshot          : getFromManager manager, snapshotName, 'map', initialSnapshot

  manager.bindRealtimeListeners refs.changes, 'list'
  manager.bindRealtimeListeners refs.broadcastMessages, 'list'
  manager.bindRealtimeListeners refs.watchMap, 'map'
  manager.bindRealtimeListeners refs.permissions, 'map'

  registerCollaborationSessionId manager, refs.participants

  return refs

getFromManager = (manager, name, defaultType, defaultValue) ->
  item   = manager.getFromModel name
  item or= manager.create defaultType, name, defaultValue

  return item

registerCollaborationSessionId = (manager, participants) ->
  collaborators = manager.getCollaborators()
  for collaborator in collaborators when collaborator.isMe
    for user, index in participants.asArray() when user.nickname is getNick()
      newData = _.assign {}, user
      newData.sessionId = collaborator.sessionId
      participants.remove index
      participants.insert index, newData

fetchParticipants = (channelId, callback) ->
  {socialapi} = kd.singletons
  socialapi.channel.listParticipants {channelId}, (err, participants) ->
    return callback err  if err
    idList = participants.map ({accountId}) -> accountId
    query  = socialApiId: $in: idList

    remote.api.JAccount.some query, {}
      .then (accounts) -> callback null, accounts

removeParticipantFromParticipantList = (references, nickname) ->
  { participants } = references
  return console.warn 'participants is not set'  unless participants

  for participant, index in participants.asArray()
    if participant.nickname is nickname
      participants.remove index
      break

removeParticipantFromMaps = (manager, nickname) ->
  myWatchMapName = "#{nickname}WatchMap"
  mySnapshotName = "#{nickname}Snapshot"

  manager.delete 'map', myWatchMapName
  manager.delete 'map', mySnapshotName

removeParticipantFromPermissions = (references, nickname) ->
  references.permissions.delete nickname

module.exports = {
  loadCollaborationFile
  createCollaborationFile
  isSessionActive
  getFileIdentifier
  getReferences
  getTargetUser
}

