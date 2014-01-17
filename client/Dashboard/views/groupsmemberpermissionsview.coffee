class GroupsMemberPermissionsView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "member-related"

    super options, data

    @_searchValue = null

    @listController = new KDListViewController
      itemClass             : GroupsMemberPermissionsListItemView
      lazyLoadThreshold     : .99
    @listWrapper    = @listController.getView()

    @listController.getListView().on 'ItemWasAdded', (view)=>
      view.on 'RolesChanged', @memberRolesChange.bind this, view
      view.on 'OwnershipChanged', @bound "refresh"

    @listController.on 'LazyLoadThresholdReached', @bound 'continueLoadingTeasers'

    @on 'teasersLoaded', =>
      unless @listController.scrollView.hasScrollBars()
        @continueLoadingTeasers()

    @refresh()

    @on 'SearchInputChanged', (value)=>
      @_searchValue = value
      if value isnt ""
        @timestamp = new Date 0
        @listController.removeAllItems()
        @fetchSomeMembers()
      else @refresh()

    KD.singletons.groupsController.on "MemberJoinedGroup", (data) =>
      @refresh()

  fetchRoles:(callback=->)->
    groupData = @getData()
    list = @listController.getListView()
    list.getOptions().group = groupData
    groupData.fetchRoles (err, roles)=>
      return warn err if err
      list.getOptions().roles = roles

  fetchSomeMembers:(selector={})->
    @listController.showLazyLoader no
    options =
      limit : 20
      sort  : { timestamp: -1 }
    # return
    if @_searchValue
      {JAccount} = KD.remote.api
      JAccount.byRelevance @_searchValue, options, (err, members)=> @populateMembers err, members
    else
      @getData().fetchMembers selector, options, (err, members)=> @populateMembers err, members

  populateMembers:(err, members)->
    return warn err if err
    @listController.hideLazyLoader()
    if members.length > 0
      ids = (member._id for member in members)
      @getData().fetchUserRoles ids, (err, userRoles)=>
        return warn err if err
        userRolesHash = {}
        for userRole in userRoles
          userRolesHash[userRole.targetId] ?= []
          userRolesHash[userRole.targetId].push userRole.as


        list = @listController.getListView()
        list.getOptions().userRoles ?= []
        list.getOptions().userRoles = _.extend(
          list.getOptions().userRoles, userRolesHash
        )

        nicknames = (member.profile.nickname for member in members)
        @getData().fetchUserStatus nicknames, (err, users)=>
          userStatusHash = {}
          for user in users
            userStatusHash[user.username] = user.status

          list.getOptions().userStatus ?= []
          list.getOptions().userStatus = _.extend(list.getOptions().userStatus, userStatusHash)
          @listController.instantiateListItems members
          @timestamp = new Date members.last.timestamp_
          @emit 'teasersLoaded' if members.length is 20

  refresh:->
    @listController.removeAllItems()
    @timestamp = new Date 0
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
