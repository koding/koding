class GroupsController extends KDController

  constructor:(options = {}, data)->

    super options, data

    @isReady       = no

    @utils.defer @bound 'init'

  init:->
    mainController    = KD.getSingleton 'mainController'
    router            = KD.getSingleton 'router'
    {entryPoint}      = KD.config
    @groups           = {}
    @currentGroupData = new GroupData

    mainController.on 'NavigationLinkTitleClick', (pageInfo)=>
      return unless pageInfo.path
      if pageInfo.topLevel
      then router.handleRoute "#{pageInfo.path}"
      else router.handleRoute "#{pageInfo.path}", {entryPoint}

  getCurrentGroup:->
    throw 'FIXME: array should never be passed'  if Array.isArray @currentGroupData.data
    return @currentGroupData.data

  openGroupChannel:(group, callback=->)->
    @groupChannel = KD.remote.subscribe "group.#{group.slug}",
      serviceType : 'group'
      group       : group.slug
      isExclusive : yes

    @forwardEvent @groupChannel, "MemberJoinedGroup"
    @forwardEvent @groupChannel, "FollowHappened"
    @forwardEvent @groupChannel, "LikeIsAdded"

    @groupChannel.once 'setSecretNames', callback

  changeGroup:(groupName='', callback=->)->

    groupName or= 'koding' # KD.defaultSlug
    return callback()  if @currentGroupName is groupName

    oldGroupName        = @currentGroupName
    @currentGroupName   = groupName

    unless groupName is oldGroupName
      KD.remote.cacheable groupName, (err, models)=>
        if err then callback err
        else if models?
          [group] = models
          if group.bongo_.constructorName isnt 'JGroup'
            @isReady = yes
          else
            @setGroup groupName
            @currentGroupData.setGroup group
            @isReady = yes
            callback null, groupName, group
            @emit 'GroupChanged', groupName, group
            @openGroupChannel group, => @emit 'GroupChannelReady'

  getUserArea:->
    @userArea ? group:
      if KD.config.entryPoint?.type is 'group'
      then KD.config.entryPoint.slug
      else (KD.getSingleton 'groupsController').currentGroupName

  setUserArea:(userArea)->
    @userArea = userArea

  getGroupSlug:-> @currentGroupName

  setGroup:(groupName)->
    @currentGroupName = groupName
    @setUserArea {
      group: groupName, user: KD.whoami().profile.nickname
    }

  joinGroup:(group, callback)->
    group.join (err, response)=>
      unless err
        callback err, response
        KD.track "Groups", "JoinedGroup", group.slug
        KD.getSingleton('mainController').emit 'JoinedGroup'

  acceptInvitation:(group, callback)->
    KD.whoami().acceptInvitation group, (err, res)=>
      mainController = KD.getSingleton "mainController"
      mainController.once "AccountChanged", callback.bind this, err, res
      mainController.accountChanged KD.whoami()

  ignoreInvitation:(group, callback)->
    KD.whoami().ignoreInvitation group, callback

  cancelGroupRequest:(group, callback)->
    KD.whoami().cancelRequest group, callback

  cancelMembershipPolicyChange:(policy, membershipPolicyView, modal)->
    membershipPolicyView.enableInvitations.setValue policy.invitationsEnabled

  updateMembershipPolicy:(group, policy, formData, membershipPolicyView, callback)->
    group.modifyMembershipPolicy formData, (err)->
      unless err
        policy.emit 'MembershipPolicyChangeSaved'
        new KDNotificationView {title:"Membership policy has been updated."}
      KD.showError err