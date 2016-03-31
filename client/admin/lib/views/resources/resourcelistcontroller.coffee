kd               = require 'kd'
remote           = require('app/remote').getInstance()
showError        = require 'app/util/showError'
getGroup         = require 'app/util/getGroup'
showNotification = require 'app/util/showNotification'

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
      group = getGroup()
      group.fetchResources query ? {}, fetchOptions, callback

    super options, data

    @filterStates.query = null

    listView = @getListView()
    listView.on 'ReloadItems', @bound 'reloadItems'
    listView.on 'ItemStatusUpdateNeeded', @bound 'requestItemStatus'

    { notificationController } = kd.singletons
    notificationController.on 'StackStatusChanged', @bound 'handleStackStatusChanged'
    notificationController.on 'StackCreated', @bound 'handleStackCreated'

    @on 'FetchProcessFailed', ->
      showError err, { KodingError: 'Failed to fetch data, try again later.' }


  reloadItems: ->

    @filterStates.skip = 0
    @loadItems()


  search: (query) ->

    @filterStates.query = query
    @loadItems()


  handleStackStatusChanged: (data) ->

    { id, status } = data
    item = do =>
      for _item in @getListItems()
         data = _item.getData()
         return _item  if data._id is id

    return  unless item

    resource = item.getData()
    resource.status = status
    item.setData resource


  handleStackCreated: ->

    showNotification 'A new stack has been created', { type : 'main' }
    @reloadItems()


  requestItemStatus: (item) ->

    resource = item.getData()
    group    = getGroup()
    group.fetchResources { _id : resource._id }, (err, stacks) ->
      return showError err  if err
      return item.destroy()  unless stack = stacks[0]

      resource.status = stack.status
      item.setData resource
