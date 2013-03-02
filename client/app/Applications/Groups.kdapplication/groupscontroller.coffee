class GroupData extends KDEventEmitter

  constructor:(currentGroup="koding")->
    super

    KD.remote.on 'ready', =>
      KD.remote.cacheable currentGroup, (err, group)=> @setGroup group

  getAt:(path)->
    JsPath.getAt @data, path

  setGroup:(group)->
    @data = group
    @emit 'update'

class GroupsController extends KDObject

  constructor:->
    super
    router = @getSingleton 'router'
    router.on 'GroupChanged', @bound 'setGroup'
    mainController = @getSingleton 'mainController'
    mainController.on 'AccountChanged', @bound 'resetUserArea'
    mainController.on 'NavigationLinkTitleClick', (pageInfo)=>
      if pageInfo.path
        {group} = @userArea
        route = "#{unless group is 'koding' then '/'+group else ''}#{pageInfo.path}"
        router.handleRoute route
    @groups = {}
    @currentGroupData = new GroupData
  
  getCurrentGroupData:-> @currentGroupData

  changeGroup:(groupName)->
    groupName ?= "koding"
    unless @currentGroup is groupName
      @setGroup groupName
      KD.remote.cacheable groupName, (err, group)=>
        @currentGroupData.setGroup group
        @emit 'GroupChanged', groupName, group

  getUserArea:-> @userArea

  setUserArea:(userArea)->
    @emit 'UserAreaChanged', userArea  if not _.isEqual(userArea, @userArea)
    @userArea = userArea

  getGroup:-> @userArea?.group

  setGroup:(groupName)->
    @currentGroup = groupName
    @setUserArea {
      group: groupName, user: KD.whoami().profile.nickname
    }

  resetUserArea:(account)->
    @setUserArea {
      group: 'koding', user: account.profile.nickname
    }

  openAdminDashboard:->
    console.log 'open admin', {arguments}