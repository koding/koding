kd        = require 'kd'
remote    = require('app/remote').getInstance()
showError = require 'app/util/showError'

KodingListController = require 'app/kodinglist/kodinglistcontroller'
{ yamlToJson }       = require 'stacks/views/stacks/yamlutils'


module.exports = class ResourceListController extends KodingListController

  constructor: (options = {}, data) ->

    options.noItemFoundText   = 'No resource found!'
    options.lazyLoadThreshold = .99
    options.fetcherMethod     = (query, fetchOptions, callback) ->
      if query
        inJson = yamlToJson query
        query  = inJson.contentObject  unless inJson.err

      query = { searchFor: query }  if typeof query is 'string'
      group = kd.singletons.groupsController.getCurrentGroup()
      group.fetchResources query ? {}, fetchOptions, callback

    super options, data

    @filterStates.query = null

    listView = @getListView()
    listView.on 'ReloadItems', @bound 'reloadItems'

    @on 'FetchProcessFailed', ->
      showError err, { KodingError: 'Failed to fetch data, try again later.' }


  reloadItems: ->

    @filterStates.skip = 0
    @loadItems()


  search: (query) ->

    @filterStates.query = query
    @loadItems()
