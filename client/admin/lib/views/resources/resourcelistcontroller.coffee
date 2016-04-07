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
    listView.on 'ItemStatusUpdateNeeded', @bound 'updateItemStatus'

    { notificationController } = kd.singletons
    notificationController.on 'StackStatusChanged', @bound 'updateItemStatus'
    notificationController.on 'StackCreated', @bound 'handleStackCreated'

    @on 'FetchProcessFailed', ->
      showError err, { KodingError: 'Failed to fetch data, try again later.' }


  reloadItems: ->

    @filterStates.skip = 0
    @loadItems()


  search: (query) ->

    @filterStates.query = query
    @loadItems()


  handleStackCreated: ->

    showNotification 'A new stack has been created', { type : 'main' }
    @reloadItems()


  findItemById: (id) ->

    for item in @getListItems()
      data = item.getData()
      return item  if data._id is id


  updateItemStatus: (params) ->

    { id } = params
    group  = getGroup()
    group.fetchResources { _id : id }, (err, stacks) =>
      return showError err  if err

      item = @findItemById id
      return  unless item
      return item.destroy()  unless stack = stacks[0]

      resource = item.getData()
      resource.status = stack.status
      item.setData resource


  destroy: ->

    { notificationController } = kd.singletons
    notificationController.off 'StackStatusChanged', @bound 'updateItemStatus'
    notificationController.off 'StackCreated', @bound 'handleStackCreated'

    super
