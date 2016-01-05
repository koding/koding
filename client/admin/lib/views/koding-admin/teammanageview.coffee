kd                 = require 'kd'

TeamList           = require './teamlist'
TeamListController = require './teamlistcontroller'


module.exports = class TeamManageView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = 'team-related'

    super options, data

    @createSearchView()
    @createTeamListView()


  createSearchView: ->

    @addSubView @searchContainer = new kd.CustomHTMLView
      cssClass : 'search'

    @searchContainer.addSubView @searchInput = new kd.HitEnterInputView
      type        : 'text'
      placeholder : "Find team with it's slug"
      callback    : @bound 'search'

    @searchContainer.addSubView @searchClear = new kd.CustomHTMLView
      tagName     : 'span'
      partial     : 'clear'
      cssClass    : 'clear-search hidden'
      click       : @bound 'clearSearch'


  createTeamListView: ->

    @listView   = new TeamList
    @controller = new TeamListController
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
