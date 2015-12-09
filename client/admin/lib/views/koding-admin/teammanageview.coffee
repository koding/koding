kd                 = require 'kd'

TeamList           = require './teamlist'
TeamListController = require './teamlistcontroller'


module.exports = class TeamManageView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = 'member-related'

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
      click       : =>
        @searchInput.setValue ''
        @searchClear.hide()
        @search()


  createTeamListView: ->

    @listView   = new TeamList
    @controller = new TeamListController
      view       : @listView
      wrapper    : no
      scrollView : no

    @addSubView @controller.getView()


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
