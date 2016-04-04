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


  createResourceListView: ->

    @listView   = new ResourceList
    @controller = new ResourceListController
      view      : @listView

    @addSubView @controller.getView()


  search: (query) ->

    @controller.search query
