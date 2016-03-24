kd = require 'kd'
KDHeaderView = kd.HeaderView
NavigationController = require '../navigation/navigationcontroller'
CommonInnerNavigationList = require './commoninnernavigationlist'


module.exports = class CommonInnerNavigationListController extends NavigationController

  constructor: (options = {}, data) ->

    options.viewOptions or=
      itemClass           : options.itemClass or CommonInnerNavigationListItem
    options.scrollView   ?= no
    options.wrapper      ?= no
    options.view        or= new CommonInnerNavigationList options.viewOptions

    super options, data

    listView = @getListView()

    listView.on 'ItemWasAdded', (view) =>
      view.on 'click', (event) =>
        unless view.getData().disabledForBeta
          @selectItem view
          @emit 'NavItemReceivedClick', view.getData()
          listView.emit 'NavItemReceivedClick', view.getData()

  loadView: (mainView) ->
    list = @getListView()
    mainView.setClass 'list'
    mainView.addSubView new KDHeaderView { size : 'small', title : @getData().title, cssClass : 'list-group-title' }
    mainView.addSubView list
    @instantiateListItems(@getData().items or [])
