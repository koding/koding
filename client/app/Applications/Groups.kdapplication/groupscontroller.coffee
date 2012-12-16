class GroupData extends KDEventEmitter

  constructor:(currentGroup="Koding")->
    super

    @data = title: currentGroup

  getAt:(path)->
    JsPath.getAt @data, path

  setGroup:(group)->
    @data = group
    @emit 'update'

class GroupsController extends KDObject

  constructor:(parentController)->
    @groups = {}
    @currentGroupData = groupData = new GroupData

    parentController.on 'GroupChanged', (groupName)=>
      KD.remote.cacheable groupName, (err, group)-> groupData.setGroup group

  getCurrentGroupData:-> @currentGroupData