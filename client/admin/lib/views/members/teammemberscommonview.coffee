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

    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= MemberItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10

    super options, data

    @skip = 0

    @createSearchView()
    @createListController()
    @fetchMembers()


  createSearchView: ->

    @addSubView @searchContainer = new KDCustomHTMLView
      cssClass: 'search hidden'
      partial : 'Sort by'

    @searchContainer.addSubView new KDSelectBox
      defaultValue  : 'nickname'
      selectOptions : [
        { title     : 'Screen name',  value : 'fullname'  }
        { title     : 'Nickname',     value : 'nickname'  }
      ]
      callback      : (value) ->

    @searchContainer.addSubView new KDHitEnterInputView
      type                    : 'text'
      placeholder             : 'Find by name/username'
      validationNotifications : yes
      validate                :
        rules                 :
          required            : yes
        messages              :
          required            : 'Please enter a name or username'
      callback                : -> kd.log ',,,,,,,,,,,,,,,,,,'


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
      return kd.warn err  if err
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
