class GroupsMemberPermissionsView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "member-related"
    options.itemLimit ?= 10

    super options, data

    @searchWrapper = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : 'searchbar'

    @search = new KDHitEnterInputView
      placeholder  : "Search..."
      name         : "searchInput"
      cssClass     : "header-search-input"
      type         : "text"
      callback     : =>
        @emit 'SearchInputChanged', @search.getValue()
        @search.focus()

    @searchIcon = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'icon search'

    @searchWrapper.addSubView @search
    @searchWrapper.addSubView @searchIcon

    @_searchValue = ""

    @listController = new KDListViewController
      itemClass             : GroupsMemberPermissionsListItemView
      lazyLoadThreshold     : .99
      noItemFoundWidget     : new KDCustomHTMLView
        cssClass : "lazy-loader hidden"
        partial  : "Member not found"
    @listWrapper    = @listController.getView()

    @listController.getListView().on 'ItemWasAdded', (view)=>
      view.on 'RolesChanged', @memberRolesChange.bind this, view
      view.on 'OwnershipChanged', @bound "refresh"

    @listController.on 'LazyLoadThresholdReached', @bound 'continueLoadingTeasers'

    @on 'teasersLoaded', =>
      unless @listController.scrollView.hasScrollBars()
        @continueLoadingTeasers()

    @on 'SearchInputChanged', (value)=>
      return  if value is @_searchValue
      @_searchValue = value

      if value isnt ""
        @skip = 0
        @listController.removeAllItems()
        @fetchSomeMembers()
      else
        @_searchValue = ""
        @refresh()

    KD.singletons.groupsController.on "MemberJoinedGroup", (data) =>
      @refresh()  unless @getData().slug is "koding"

    @once 'viewAppended', @bound '_windowDidResize'
    @listenWindowResize()

    @refresh()

  fetchRoles:(callback=->)->
    groupData = @getData()
    list = @listController.getListView()
    list.getOptions().group = groupData
    groupData.fetchRoles (err, roles)=>
      return warn err if err
      list.getOptions().roles = roles

  fetchSomeMembers:->
    @listController.showLazyLoader no
    #some older accounts does not have proper timestamp values
    #because of this skip parameter is used here for lazy loading
    options =
      limit : @getOptions().itemLimit
      sort  : { timestamp: -1 }
      skip  : @skip

    if @_searchValue
      selector = @_searchValue
      {JAccount} = KD.remote.api
    else
      selector = ""
    @getData().searchMembers selector, options, (err, members)=> @populateMembers err, members

  populateMembers:(err, members)->
    instantiateItems = (err) =>
      return warn err  if err
      @listController.instantiateListItems members
      @emit 'teasersLoaded' if members.length is @getOptions().itemLimit

    return warn err if err
    @listController.hideLazyLoader()
    @skip += members.length
    if members.length > 0
      @fetchUserRoles members, (err) =>
        return warn err  if err
        #no need to fetch user status for all group admins
        if @getData().slug is "koding"
          @fetchUserStatus members, instantiateItems
        else
          instantiateItems()

  fetchUserRoles:(members, callback) ->
    ids = (member._id for member in members)
    @getData().fetchUserRoles ids, (err, userRoles)=>
      return callback err  if err
      userRolesHash = {}
      for userRole in userRoles
        userRolesHash[userRole.targetId] ?= []
        userRolesHash[userRole.targetId].push userRole.as

      list = @listController.getListView()
      list.getOptions().userRoles ?= {}
      {userRoles} = list.getOptions()
      userRoles = _.extend(
        userRoles, userRolesHash
      )
      callback null

  fetchUserStatus: (members, callback) ->
    nicknames = (member.profile.nickname for member in members)
    @getData().fetchUserStatus nicknames, (err, users)=>
      return callback err  if err
      userStatusHash = {}
      for user in users
        userStatusHash[user.username] = user.status

      list = @listController.getListView()
      list.getOptions().userStatus ?= {}
      {userStatus} = list.getOptions()
      userStatus = _.extend(userStatus, userStatusHash)
      callback null

  refresh:->
    @listController.removeAllItems()
    @skip = 0
    @fetchRoles()
    @fetchSomeMembers()

  continueLoadingTeasers:->
    @listController.showLazyLoader no
    @fetchSomeMembers()

  memberRolesChange:(view, member, roles)->
    @getData().changeMemberRoles member.getId(), roles, (err)=>
      view.updateRoles roles  unless err

  pistachio:->
    """
    {{> @searchWrapper}}
    {{> @listWrapper}}
    """
