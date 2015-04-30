kd                   = require 'kd'
KDView               = kd.View
MemberItemView       = require './memberitemview'
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDListViewController = kd.ListViewController


module.exports = class TeamMembersCommonView extends KDView

  constructor: (options = {}, data) ->

    options.noItemFoundWidget   or= new KDCustomHTMLView
    options.listViewItemClass   or= MemberItemView
    options.listViewItemOptions or= {}
    options.itemLimit            ?= 10

    super options, data

    @skip = 0

    @createListController()
    @fetchMembers()


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
