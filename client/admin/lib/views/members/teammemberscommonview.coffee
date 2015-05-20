kd                   = require 'kd'
KDView               = kd.View
whoami               = require 'app/util/whoami'
KDSelectBox          = kd.SelectBox
KDListItemView       = kd.ListItemView
MemberItemView       = require './memberitemview'
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView


module.exports = class TeamMembersCommonView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass                 = 'members-commonview'
    options.itemLimit               ?= 10
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

    @listController.on 'LazyLoadThresholdReached', @bound 'fetchMembers'


  fetchMembers: ->

    return if @isFetching

    @isFetching = yes

    group    = @getData()
    options  =
      limit  : @getOptions().itemLimit
      # sort   : timestamp: -1 # timestamp is at relationship collection
      skip   : @skip

    # fetch members as jAccount
    group.fetchMembers {}, options, (err, members) =>

      return @handleError err  if err

      # collect account ids to fetch user roles
      ids = members.map (member) -> return member.getId()

      myAccountId = whoami().getId()
      ids.push myAccountId

      group.fetchUserRoles ids, (err, roles) =>
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

        @listMembers members, userRoles[myAccountId]
        @isFetching = no


  handleError: (err) ->

    @listController.lazyLoader.hide()
    kd.warn err


  listMembers: (members, loggedInUserRoles) ->

    unless members.length
      @listController.lazyLoader.hide()
      return @listController.noItemView.show()

    @skip += members.length

    for member in members
      member.loggedInUserRoles = loggedInUserRoles # FIXME
      @listController.addItem member

    @listController.lazyLoader.hide()
    @searchContainer.show()


  search: ->

    @skip  = 0
    @query = @searchInput.getValue()

    @refresh()


  refresh: ->

    @listController.removeAllItems()
    @listController.lazyLoader.show()
    @fetchMembers()
