globals = require 'globals'
getGroup = require '../util/getGroup'
remote = require('../remote').getInstance()
trackEvent = require '../util/trackEvent'
whoami = require '../util/whoami'
showError = require '../util/showError'
kd = require 'kd'
KDController = kd.Controller
KDNotificationView = kd.NotificationView
GroupData = require './groupdata'


module.exports = class GroupsController extends KDController

  constructor:(options = {}, data)->

    super options, data

    @isReady = no

    @init()

  init:->
    mainController    = kd.getSingleton 'mainController'
    router            = kd.getSingleton 'router'
    {entryPoint}      = globals.config
    @groups           = {}
    @currentGroupData = new GroupData
    @currentGroupData.setGroup globals.currentGroup

    mainController.ready =>
      { slug } = entryPoint  if entryPoint?.type is 'group'
      @changeGroup slug

  getCurrentGroup:->
    throw 'FIXME: array should never be passed'  if Array.isArray @currentGroupData.data
    return @currentGroupData.data

  filterXssAndForwardEvents: (target, events) ->
    events.forEach (event) =>
      target.on event, (rest...) =>
        rest = remote.revive rest
        @emit event, rest...

  openGroupChannel:(group, callback=->)->
    @groupChannel = remote.subscribe "group.#{group.slug}",
      serviceType : 'group'
      group       : group.slug
      isExclusive : yes

    @filterXssAndForwardEvents @groupChannel, [
      'MemberJoinedGroup'
      'FollowHappened'
      'LikeIsAdded'
      'PostIsCreated'
      'ReplyIsAdded'
      'PostIsDeleted'
      'LikeIsRemoved'
    ]

    @groupChannel.once 'setSecretNames', callback

  changeGroup: (groupName = 'koding', callback = kd.noop) ->

    return callback()  if @currentGroupName is groupName

    oldGroupName        = @currentGroupName
    @currentGroupName   = groupName

    remote.cacheable groupName, (err, models)=>
      if err then callback err
      else if models?
        [group] = models
        if group.bongo_.constructorName isnt 'JGroup'
          @changeGroup 'koding'
        else
          @setGroup groupName
          @currentGroupData.setGroup group
          callback null, groupName, group
          @openGroupChannel getGroup()
          @emit 'ready'

  getUserArea:->
    @userArea ? group:
      if globals.config.entryPoint?.type is 'group'
      then globals.config.entryPoint.slug
      else (kd.getSingleton 'groupsController').currentGroupName

  setUserArea:(userArea)->
    @userArea = userArea

  getGroupSlug:-> @currentGroupName

  setGroup:(groupName)->
    @currentGroupName = groupName
    @setUserArea {
      group: groupName, user: whoami().profile.nickname
    }

  joinGroup:(group, callback)->
    group.join (err, response)=>
      return showError err  if err?
      callback err, response
      kd.getSingleton('mainController').emit 'JoinedGroup'
      trackEvent "Join group, success", slug:group.slug

  acceptInvitation:(group, callback)->
    whoami().acceptInvitation group, (err, res)=>
      mainController = kd.getSingleton "mainController"
      mainController.once "AccountChanged", callback.bind this, err, res
      mainController.accountChanged whoami()

  ignoreInvitation:(group, callback)->
    whoami().ignoreInvitation group, callback

  cancelGroupRequest:(group, callback)->
    whoami().cancelRequest group.slug, callback

  cancelMembershipPolicyChange:(policy, membershipPolicyView, modal)->
    membershipPolicyView.enableInvitations.setValue policy.invitationsEnabled

  updateMembershipPolicy:(group, policy, formData, membershipPolicyView, callback)->
    group.modifyMembershipPolicy formData, (err)->
      unless err
        policy.emit 'MembershipPolicyChangeSaved'
        new KDNotificationView {title:"Membership policy has been updated."}
      showError err

