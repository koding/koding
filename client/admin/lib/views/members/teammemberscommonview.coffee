kd                   = require 'kd'
KDView               = kd.View
whoami               = require 'app/util/whoami'
KDSelectBox          = kd.SelectBox
KDListItemView       = kd.ListItemView
MemberItemView       = require './memberitemview'
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView
remote               = require('app/remote').getInstance()


module.exports = class TeamMembersCommonView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass                 = 'members-commonview'
    options.itemLimit               ?= 10
    options.fetcherMethod          or= 'fetchMembersWithEmail'
    options.noItemFoundWidget      or= new KDCustomHTMLView
    options.listViewItemClass      or= MemberItemView
    options.listViewItemOptions    or= {}
    options.searchInputPlaceholder or= 'Find by name/username'
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

    { sortOptions } = @getOptions()

    @addSubView @searchContainer = new KDCustomHTMLView
      cssClass : 'search hidden'
      partial  : '<span class="label">Sort by</span>'

    @searchContainer.addSubView @sortSelectBox = new KDSelectBox
      defaultValue  : sortOptions.first.value
      selectOptions : sortOptions
      callback      : @bound 'search'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : @getOptions().searchInputPlaceholder
      callback    : @bound 'search'

    @searchContainer.addSubView @searchClear = new KDCustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : =>
        @searchInput.setValue ''
        @search()
        @searchClear.hide()


  createListController: ->

    { listViewItemClass, noItemFoundWidget, listViewItemOptions } = @getOptions()

    @listController       = new KDListViewController
      viewOptions         :
        wrapper           : yes
        itemClass         : listViewItemClass
        itemOptions       : listViewItemOptions
      noItemFoundWidget   : noItemFoundWidget
      useCustomScrollView : yes
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    @addSubView @listController.getView()

    @listController.on 'LazyLoadThresholdReached', =>
      if @searchInput.getValue()
        unless @isFetching
          @isFetching = yes
          @page++
          @search()
      else
        @fetchMembers()


  fetchMembers: ->

    return if @isFetching

    @isFetching = yes

    group    = @getData()
    method   = @getOption 'fetcherMethod'
    options  =
      limit  : @getOptions().itemLimit
      sort   : timestamp: -1 # timestamp is at relationship collection
      skip   : @skip

    # fetch members as jAccount
    group[method] {}, options, (err, members) =>

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

      @loggedInUserRoles = userRoles[myAccountId]

      callback members


  handleError: (err) ->

    @page = 0

    if err?.message?.indexOf('No account found') > -1
      @search yes
    else
      @listController.lazyLoader.hide()
      kd.warn err


  listMembers: (members) ->

    if members.length is 0 and @listController.getItemCount() is 0
      @listController.lazyLoader.hide()
      @listController.noItemView.show()
      return

    @skip += members.length

    @fetchUserRoles members, (members) =>
      for member in members
        member.loggedInUserRoles = @loggedInUserRoles # FIXME
        @listController.addItem member

    @listController.lazyLoader.hide()
    @searchContainer.show()


  search: (useSearchMembersMethod = no) ->

    query = @searchInput.getValue()

    if query is ''
      @page = 0
      @skip = 0
      @searchClear.hide()
      @resetListItems()
      return @fetchMembers()

    @page      = 0  if query isnt @lastQuery
    options    = { @page, restrictSearchableAttributes: [ 'nick', 'email' ] }
    @lastQuery = query
    group      = @getData()

    @searchClear.show()

    if useSearchMembersMethod is yes # explicit check for truthy value
      group.searchMembers query, {}, (err, accounts) =>
        if accounts.length
          @handleSearchResult accounts
        else
          @handleError err
    else
      kd.singletons.search.searchAccounts query, options
        .then (accounts) => @handleSearchResult accounts
        .catch (err) =>
          @handleError err


  handleSearchResult: (accounts) ->

    usernames = (profile.nickname for { profile } in accounts)

    # Send a request to back-end for user emails.
    remote.api.JAccount.fetchEmailsByUsername usernames, (err, emails) =>

      @resetListItems no  if err

      for account in accounts
        { profile }   = account
        profile.email = emails[profile.nickname]

      @resetListItems no  if @page is 0
      @listMembers accounts
      @isFetching = no


  resetListItems: (showLoader = yes) ->

    @skip = 0
    @listController.removeAllItems()
    @listController.lazyLoader.show()


  refresh: ->

    @resetListItems()
    @fetchMembers()
