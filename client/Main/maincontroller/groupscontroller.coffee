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

    mainController.ready =>
      {slug} = entryPoint  if entryPoint?.type is 'group'
      @changeGroup slug

  getCurrentGroup:->
    throw 'FIXME: array should never be passed'  if Array.isArray @currentGroupData.data
    return @currentGroupData.data

  filterXssAndForwardEvents: (target, events) ->
    events.forEach (event) =>
      target.on event, (rest...) =>
        rest = KD.remote.revive rest
        @emit event, rest...

  openGroupChannel:(group, callback=->)->
    @groupChannel = KD.remote.subscribe "group.#{group.slug}",
      serviceType : 'group'
      group       : group.slug
      isExclusive : yes

    @filterXssAndForwardEvents @groupChannel, [
      "MemberJoinedGroup"
      "FollowHappened"
      "LikeIsAdded"
      "PostIsCreated"
      "ReplyIsAdded"
      "PostIsDeleted"
      "LikeIsRemoved"
    ]

    @groupChannel.once 'setSecretNames', callback

  changeGroup:(groupName = 'koding', callback = (->))->
    return callback()  if @currentGroupName is groupName

    oldGroupName        = @currentGroupName
    @currentGroupName   = groupName

    KD.remote.cacheable groupName, (err, models)=>
      if err then callback err
      else if models?
        [group] = models
        if group.bongo_.constructorName isnt 'JGroup'
          @changeGroup 'koding'
        else
          @setGroup groupName
          @currentGroupData.setGroup group
          callback null, groupName, group
          @openGroupChannel KD.getGroup()
          @emit 'ready'


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
      return KD.showError err  if err?
      callback err, response
      KD.getSingleton('mainController').emit 'JoinedGroup'
      KD.mixpanel "Join group, success", slug:group.slug

  acceptInvitation:(group, callback)->
    KD.whoami().acceptInvitation group, (err, res)=>
      mainController = KD.getSingleton "mainController"
      mainController.once "AccountChanged", callback.bind this, err, res
      mainController.accountChanged KD.whoami()

  ignoreInvitation:(group, callback)->
    KD.whoami().ignoreInvitation group, callback

  cancelGroupRequest:(group, callback)->
    KD.whoami().cancelRequest group.slug, callback

  cancelMembershipPolicyChange:(policy, membershipPolicyView, modal)->
    membershipPolicyView.enableInvitations.setValue policy.invitationsEnabled

  updateMembershipPolicy:(group, policy, formData, membershipPolicyView, callback)->
    group.modifyMembershipPolicy formData, (err)->
      unless err
        policy.emit 'MembershipPolicyChangeSaved'
        new KDNotificationView {title:"Membership policy has been updated."}
      KD.showError err
