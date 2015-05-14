kd                   = require 'kd'
KDView               = kd.View
KDSelectBox          = kd.SelectBox
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDHitEnterInputView  = kd.HitEnterInputView

MemberItemView = require './memberitemview'


module.exports = class TeamMembersCommonView extends KDView

  constructor: (options = {}, data) ->

    options.noItemFoundWidget      or= new KDCustomHTMLView
    options.listViewItemClass      or= MemberItemView
    options.listViewItemOptions    or= {}
    options.searchInputPlaceholder or= 'Find by name/username'
    options.itemLimit               ?= 10

    super options, data

    @skip = 0

    @createSearchView()
    @createListController()
    @fetchMembers()


  createSearchView: ->

    @addSubView @searchContainer = new KDCustomHTMLView
      cssClass: 'search hidden'
      partial : '<span class="label">Sort by</span>'

    @searchContainer.addSubView @sortSelectBox = new KDSelectBox
      defaultValue  : 'nickname'
      selectOptions : [
        { title     : 'Screen name',  value : 'fullname'  }
        { title     : 'Nickname',     value : 'nickname'  }
      ]
      callback      : (value) ->

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

    selector = @query or ''
    options  =
      limit  : @getOptions().itemLimit
      sort   : { timestamp: -1 }
      skip   : @skip

    @getData().searchMembers selector, options, (err, members) =>
      if err
        @listController.lazyLoader.hide()
        return kd.warn err

      @listMembers members
      @isFetching = no


  listMembers: (members) ->

    unless members.length
      return @listController.lazyLoader.hide()

    @skip += members.length

    for member in members
      @listController.addItem member

    @listController.lazyLoader.hide()
    @searchContainer.show()


  search: ->

    @skip  = 0
    @query = @searchInput.getValue()

    @listController.removeAllItems()
    @listController.lazyLoader.show()
    @fetchMembers()
