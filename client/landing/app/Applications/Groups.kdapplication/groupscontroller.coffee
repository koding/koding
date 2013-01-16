class GroupData extends KDEventEmitter

  constructor:(currentGroup="koding")->
    super

    KD.remote.on 'ready', =>
      console.log "it's ready", this
      KD.remote.cacheable currentGroup, (err, group)=> @setGroup group

  getAt:(path)->
    JsPath.getAt @data, path

  setGroup:(group)->
    @data = group
    @emit 'update'

class GroupsController extends KDObject

  constructor:(parentController)->
    @groups = {}
    @currentGroupData = groupData = new GroupData

    parentController.on 'GroupChanged', (groupName)->
      KD.remote.cacheable groupName, (err, group)->
        groupData.setGroup group
        parentController.emit 'GroupChangeFinished'

  getCurrentGroupData:-> @currentGroupData