kd                     = require 'kd'

ResourceSearchView     = require './resourcesearchview'
ResourceList           = require './resourcelist'
ResourceListController = require './resourcelistcontroller'


module.exports = class AdminResourcesView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = 'member-related resource-management environments-modal'

    super options, data

    @createSearchView()
    @createResourceListView()


  createSearchView: ->

    @addSubView @searchView = new ResourceSearchView()
    @searchView.on 'SearchRequested', @bound 'search'
    @searchView.on 'AdvancedSearchMode', @lazyBound 'changeSearchMode', yes
    @searchView.on 'RegularSearchMode', @lazyBound 'changeSearchMode', no


  createResourceListView: ->

    @listView   = new ResourceList
    @controller = new ResourceListController
      view      : @listView

    @addSubView @controller.getView()


  changeSearchMode: (isAdvanced) ->

    if isAdvanced
      @setClass 'advanced-search-mode'
    else
      @unsetClass 'advanced-search-mode'

    @controller.customScrollView.wrapper.emit 'MutationHappened'


  search: (query) ->

    @controller.search query
