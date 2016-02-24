kd                     = require 'kd'

ResourceList           = require './resourcelist'
ResourceListController = require './resourcelistcontroller'


module.exports = class AdminResourcesView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = 'member-related resource-management environments-modal'

    super options, data

    @createSearchView()
    @createResourceListView()


  createSearchView: ->

    @addSubView @searchContainer = new kd.CustomHTMLView
      cssClass : 'search'

    @searchContainer.addSubView @searchInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : 'Search in resources...'
      callback    : @bound 'search'

    @searchContainer.addSubView @searchClear = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : @bound 'clearSearch'


  createResourceListView: ->

    @listView   = new ResourceList
    @controller = new ResourceListController
      view      : @listView

    @addSubView @controller.getView()

    @listView.on 'ReloadRequested', @bound 'clearSearch'


  clearSearch: ->
    @lastQuery = null
    @searchInput.setValue ''
    @searchClear.hide()
    @search()


  search: ->

    query = @searchInput.getValue()
    isQueryEmpty   = query is ''
    isQueryChanged = query isnt @lastQuery

    if isQueryEmpty or isQueryChanged
      @searchClear.hide()
      return @controller.loadItems()  if isQueryEmpty

    return  if @lastQuery and not isQueryChanged

    @lastQuery = query
    @searchClear.show()

    @controller.loadItems query
