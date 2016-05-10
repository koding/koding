kd                        = require 'kd'
KDView                    = kd.View
KDSelectBox               = kd.SelectBox
KDCustomHTMLView          = kd.CustomHTMLView
KDHitEnterInputView       = kd.HitEnterInputView
whoami                    = require 'app/util/whoami'
remote                    = require('app/remote').getInstance()
MemberItemView            = require './memberitemview'
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
TeamMembersListController = require './teammemberslistcontroller'


module.exports = class TeamMembersCommonView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass                    = 'members-commonview'
    options.itemLimit                  ?= 10
    options.fetcherMethod             or= 'fetchMembersWithEmail'
    options.listViewItemOptions       or= {}
    options.listViewItemClass         or= null
    options.searchInputPlaceholder    or= 'Find by name/username'
    options.showSearchFieldAtFirst    or= no
    options.useCustomThresholdHandler  ?= yes
    options.sortOptions               or= [
      { title: 'Screen name',   value: 'fullname' }
      { title: 'Nickname',      value: 'nickname' }
    ]

    super options, data

    @page = 0

    @createSearchView()
    @createListController()


  createSearchView: ->

    { sortOptions, showSearchFieldAtFirst } = @getOptions()

    @searchContainer = new KDCustomHTMLView
      cssClass : 'search'
      partial  : '<span class="label">Sort by</span>'

    @searchContainer.hide()  unless showSearchFieldAtFirst

    @addSubView @searchContainer

    @searchContainer.addSubView @sortSelectBox = new KDSelectBox
      defaultValue  : sortOptions.first.value
      selectOptions : sortOptions
      callback      : @bound 'search'

    @searchContainer.addSubView @searchInput = new KDHitEnterInputView
      type        : 'text'
      placeholder : @getOptions().searchInputPlaceholder
      callback    : => @search()

    @searchContainer.addSubView @searchClear = new KDCustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : =>
        @searchInput.setValue ''
        @searchClear.hide()
        @search()


  createListController: ->

    { noItemFoundText, listViewItemOptions, fetcherMethod, listViewItemClass, memberType, defaultMemberRole } = @getOptions()
    group = @getData()

    @listController       = new TeamMembersListController
      memberType          : memberType
      defaultMemberRole   : defaultMemberRole
      noItemFoundText     : noItemFoundText
      itemClass           : listViewItemClass or MemberItemView
      viewOptions         :
        wrapper           : yes
        itemOptions       : listViewItemOptions
      fetcherMethod       : (query, fetchOptions, callback) ->
        group[fetcherMethod] query, fetchOptions, callback
    , group

    @buildListController()


  buildListController: ->

    { useCustomThresholdHandler } = @getOptions()

    @addSubView @listController.getView()

    if useCustomThresholdHandler
      @listController.on 'LazyLoadThresholdReached', =>
        if @searchInput.getValue()
          unless @isFetching
            @isFetching = yes
            @page++
            @search no, yes
        else
          @fetchMembers()

    @listController
      .on 'CalculateAndFetchMoreIfNeeded',  @bound 'calculateAndFetchMoreIfNeeded'
      .on 'ShowSearchContainer',            @searchContainer.bound 'show'
      .on 'HideSearchContainer',            @searchContainer.bound 'hide'
      .on 'ErrorHappened',                  @bound 'handleError'


  fetchMembers: ->

    return if @isFetching

    @isFetching = yes

    { fetcherMethod, itemLimit } = @getOptions()

    group   = @getData()
    options =
      limit : itemLimit
      sort  : { timestamp: -1 } # timestamp is at relationship collection
      skip  : @listController.filterStates.skip

    # fetch members as jAccount
    group[fetcherMethod] {}, options, (err, members) =>

      return @handleError err  if err

      @listController.addListItems members
      @isFetching = no


  handleError: (err) ->

    @page = 0

    if err?.message?.indexOf('No account found') > -1
      @search yes
    else
      @listController.hideLazyLoader()
      kd.warn err


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
      @listController.filterStates.skip = 0
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
      @listController.addListItems accounts, yes
      @isFetching = no


  resetListItems: (showLoader = yes) ->

    @listController.filterStates.skip = 0
    @listController.removeAllItems()
    @listController.hideNoItemWidget()
    @listController.lazyLoader.show()


  refresh: ->

    @resetListItems()
    @fetchMembers()
