_ = require 'lodash'
kd = require 'kd'
KDListViewController = kd.ListViewController
GroupsBlockedUserListItemView = require './groupsblockeduserlistitemview'
remote = require('app/remote').getInstance()
JView = require 'app/jview'


module.exports = class GroupsBlockedUserView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "member-related"

    super options, data

    @listController = new KDListViewController
      itemClass             : GroupsBlockedUserListItemView
      lazyLoadThreshold     : .99
    @listWrapper    = @listController.getView()

    @listController.getListView().on 'ItemWasAdded', (view)=>
      view.on 'RolesChanged', @memberRolesChange.bind this, view

    @listController.on 'LazyLoadThresholdReached', @bound 'continueLoadingTeasers'

    @on 'teasersLoaded', =>
      unless @listController.scrollView.hasScrollBars()
        @continueLoadingTeasers()

    @refresh()

  fetchRoles:(callback=->)->
    groupData = @getData()
    list = @listController.getListView()
    list.getOptions().group = groupData
    groupData.fetchRoles (err, roles)=>
      return kd.warn err if err
      list.getOptions().roles = roles

  fetchSomeMembers:(selector={})->
    @listController.showLazyLoader no
    options =
      limit : 10

    {JAccount} = remote.api
    JAccount.fetchBlockedUsers options, (err, blockedUsers) => @populateBlockedUsers err, blockedUsers

  populateBlockedUsers:(err, users)->
    return kd.warn err if err
    @listController.hideLazyLoader()

    if users.length > 0
      ids = (member._id for member in users)
      @getData().fetchUserRoles ids, (err, userRoles)=>
        return kd.warn err if err
        userRolesHash = {}
        for userRole in userRoles
          userRolesHash[userRole.targetId] ?= []
          userRolesHash[userRole.targetId].push userRole.as

        list = @listController.getListView()
        listOptions = list.getOptions()
        listOptions.userRoles ?= []
        listOptions.userRoles = _.extend listOptions.userRoles, userRolesHash

        @listController.instantiateListItems users
        @timestamp = new Date users.last.timestamp_
        @emit 'teasersLoaded' if users.length is 20

  refresh:->
    @listController.removeAllItems()
    @timestamp = new Date()
    @fetchRoles()
    @fetchSomeMembers()

  continueLoadingTeasers:->
    @fetchSomeMembers {timestamp: $lt: @timestamp.getTime()}

  memberRolesChange:(view, member, roles)->
    @getData().changeMemberRoles member.getId(), roles, (err)=>
      view.updateRoles roles  unless err

  pistachio:->
    """
    {{> @listWrapper}}
    """


