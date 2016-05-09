kd             = require 'kd'
whoami         = require 'app/util/whoami'
MemberItemView = require 'admin/views/members/memberitemview'
remote         = require('app/remote').getInstance()


module.exports = class HomeTeamTeammates extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass               or= kd.utils.curry 'members-commonview', options.cssClass
    options.itemLimit               ?= 10
    options.fetcherMethod          or= 'fetchMembersWithEmail'
    options.noItemFoundWidget      or= new kd.CustomHTMLView
    options.listViewItemClass      or= MemberItemView
    options.listViewItemOptions    or= {}
    options.searchInputPlaceholder or= 'Find by name/username'
    options.showSearchFieldAtFirst or= no
    options.sortOptions            or= [
      { title: 'Screen name',   value: 'fullname' }
      { title: 'Nickname',      value: 'nickname' }
    ]

    super options, data

    @skip = 0
    @page = 0

    @createSearchView()
    @createListController()
    @fetchMembers()


  createSearchView: ->

    { sortOptions, showSearchFieldAtFirst } = @getOptions()

    @searchContainer = new kd.CustomHTMLView
      cssClass : 'search'
      partial  : '<span class="label">Sort by</span>'

    @searchContainer.hide()  unless showSearchFieldAtFirst

    @addSubView @searchContainer

    @searchContainer.addSubView @sortSelectBox = new kd.SelectBox
      defaultValue  : sortOptions.first.value
      selectOptions : sortOptions
      callback      : @bound 'search'

    @searchContainer.addSubView @searchInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : @getOptions().searchInputPlaceholder
      callback    : @bound 'search'

    @searchContainer.addSubView @searchClear = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : =>
        @searchInput.setValue ''
        @search()
        @searchClear.hide()


  createListController: ->

    { listViewItemClass, noItemFoundWidget, listViewItemOptions } = @getOptions()

    @listController       = new kd.ListViewController
      viewOptions         :
        itemClass         : listViewItemClass
        itemOptions       : listViewItemOptions
      noItemFoundWidget   : noItemFoundWidget
      wrapper             : no
      scrollView          : no
      useCustomScrollView : no
      startWithLazyLoader : yes
      lazyLoaderOptions   :
        spinnerOptions    : { size: { width: 28 } }

    @addSubView @listController.getView()

    @listController.on 'LazyLoadThresholdReached', =>
      if @searchInput.getValue()
        unless @isFetching
          @isFetching = yes
          @page++
          @search no, yes
      else
        @fetchMembers()


  fetchMembers: ->

    return if @isFetching

    @isFetching = yes

    { fetcherMethod, itemLimit } = @getOptions()

    group   = @getData()
    options =
      limit : itemLimit
      sort  : { timestamp: -1 } # timestamp is at relationship collection
      skip  : @skip

    # fetch members as jAccount
    group[fetcherMethod] {}, options, (err, members) =>

      return @handleError err  if err

      @listMembers members
      @isFetching = no


  fetchUserRoles: (members, callback) ->

    # collect account ids to fetch user roles
    ids = members.map (member) -> return member.getId()

    myAccountId = whoami().getId()
    ids.push myAccountId

    @getData().fetchUserRoles ids, (err, roles) =>
      return @handleError err  if err

      # create account id and roles map
      userRoles = {}

      # roles array is a flat array which means when you query for an account
      # the response would be 3 items array which contains different roles for
      # the same user. create an array by user and collect all roles belong
      # to that user.
      for role in roles
        list = userRoles[role.targetId] or= []
        list.push role.as

      # save user role array into jAccount as jAccount.role
      for member in members
        roles = userRoles[member.getId()]
        member.roles = roles  if roles

      @loggedInUserRoles = userRoles[myAccountId] ? ['owner', 'admin', 'member']

      callback members


  handleError: (err) ->

    @page = 0

    if err?.message?.indexOf('No account found') > -1
      @search yes
    else
      @listController.lazyLoader.hide()
      kd.warn err


  listMembers: (members, filterForDefaultRole) ->

    { memberType, itemLimit, defaultMemberRole } = @getOptions()

    group = @getData()
    member._currentGroup = group for member in members

    if members.length is 0 and @listController.getItemCount() is 0
      @listController.lazyLoader.hide()
      @listController.showNoItemWidget()
      return

    @skip += members.length

    if memberType is 'Blocked'
      @listController.addItem member  for member in members
      @calculateAndFetchMoreIfNeeded()  if members.length is itemLimit
    else
      @fetchUserRoles members, (members) =>

        if filterForDefaultRole and defaultMemberRole
          members = members.filter (member) ->
            return defaultMemberRole in member.roles

        if members.length
          members.forEach (member) =>
            member.loggedInUserRoles = @loggedInUserRoles # FIXME
            item = @listController.addItem member

          @calculateAndFetchMoreIfNeeded()  if members.length is itemLimit
        else
          @listController.showNoItemWidget()

    @listController.lazyLoader.hide()
    @searchContainer.show()


  calculateAndFetchMoreIfNeeded: ->

    listCtrl = @listController

    viewHeight = listCtrl.getView().getHeight()
    listHeight = listCtrl.getListView().getHeight()

    if listHeight <= viewHeight
      listCtrl.lazyLoader.show()

      if query = @searchInput.getValue() then @search()
      else
        @fetchMembers yes


  search: (useSearchMembersMethod = no, loadWithScroll = no) ->

    @resetListItems()
    @listController.lazyLoader.show()

    query          = @searchInput.getValue()
    isQueryEmpty   = query is ''
    isQueryChanged = query isnt @lastQuery

    if isQueryEmpty or isQueryChanged
      @page = 0
      @skip = 0
      @searchClear.hide()
      return @fetchMembers()  if isQueryEmpty

    @page      = if loadWithScroll then @page + 1 else 0
    group      = @getData()
    options    = {
      @page,
      restrictSearchableAttributes: [ 'nick', 'email' ],
      showCurrentUser : yes
    }
    @lastQuery = query

    @searchClear.show()

    if useSearchMembersMethod is yes # explicit check for truthy value
      group.searchMembers query, {}, (err, accounts) =>
        if accounts.length
          @handleSearchResult accounts
        else
          @handleError err
          @listController.showNoItemWidget()
    else
      kd.singletons.search.searchAccounts query, options
        .then (accounts) => @handleSearchResult accounts
        .catch (err)     => @handleError err


  handleSearchResult: (accounts) ->


    usernames = (profile.nickname for { profile } in accounts)

    # Send a request to back-end for user emails.
    remote.api.JAccount.fetchEmailsByUsername usernames, (err, emails) =>

      @resetListItems no  if err

      for account in accounts
        { profile }   = account
        profile.email = emails[profile.nickname]

      @resetListItems no  if @page is 0
      @listMembers accounts, yes
      @isFetching = no


  resetListItems: (showLoader = yes) ->

    @skip = 0
    @listController.removeAllItems()
    @listController.hideNoItemWidget()
    @listController.lazyLoader.show()


  refresh: ->

    @resetListItems()
    @fetchMembers()
