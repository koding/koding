class GroupsMemberPermissionsView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "groups-member-permissions-view"

    super options, data

    @_searchValue = null

    @search = new KDHitEnterInputView
      placeholder  : "Search..."
      name         : "searchInput"
      cssClass     : "header-search-input"
      type         : "text"
      callback     : =>
        @_searchValue = @search.getValue()
        @timestamp = new Date 0
        @listController.removeAllItems()
        @fetchSomeMembers()
        @search.focus()
      keyup        : =>
        if @search.getValue() is ""
          @_searchValue = null
          @refresh()

    @searchIcon = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'icon search'

    @listController = new KDListViewController
      itemClass             : GroupsMemberPermissionsListItemView
      lazyLoadThreshold     : .99
    @listWrapper    = @listController.getView()

    @listController.getListView().on 'ItemWasAdded', (view)=>
      view.on 'RolesChanged', @bound 'memberRolesChange'

    @listController.on 'LazyLoadThresholdReached', @bound 'continueLoadingTeasers'

    @on 'teasersLoaded', =>
      unless @listController.scrollView.hasScrollBars()
        @continueLoadingTeasers()

    @refresh()
    @listenWindowResize()

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

        @listController.instantiateListItems members
        @timestamp = new Date members.last.timestamp_
        @emit 'teasersLoaded' if members.length is 20
    else
      @listController.showNoItemWidget()

  refresh:->
    @listController.removeAllItems()
    @timestamp = new Date 0
    @fetchRoles()
    @fetchSomeMembers()

  continueLoadingTeasers:->
    @fetchSomeMembers {timestamp: $lt: @timestamp.getTime()}

  memberRolesChange:(member, roles)->
    @getData().changeMemberRoles member.getId(), roles, (err)-> console.log {arguments}

  viewAppended:->

    super
    @_windowDidResize()

  _windowDidResize:->

    @listWrapper.setHeight @parent.getHeight() - @$('section.searchbar.kdheaderview').height()

  pistachio:->
    """
    <section class='searchbar kdheaderview'>
      <span class='title'>{{ #(title)}} Members</span>{{> @search}}{{> @searchIcon}}
    </section>
    {{> @listWrapper}}
    """