kd        = require 'kd'
remote    = require('app/remote').getInstance()
showError = require 'app/util/showError'

AccountListViewController = require 'account/controllers/accountlistviewcontroller'


module.exports = class ResourceListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options = kd.utils.extend {}, options,
      limit               : 10
      noItemFoundText     : 'No resource found!'
      useCustomScrollView : yes
      startWithLazyLoader : yes
      lazyLoadThreshold   : .99
      lazyLoaderOptions   :
        spinnerOptions    :
          size            : width: 28

    super options, data

    @states =
      skip  : 0
      busy  : no
      query : null

    listView = @getListView()
    listView.on 'ReloadItems', @bound 'loadItems'


  followLazyLoad: ->

    @on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return  @hideLazyLoader()  if @states.busy

      @states.busy  = yes
      @states.skip += @getOption 'limit'

      @fetch @states.query, (err, resources) =>

        @hideLazyLoader()

        if err or not resources
          return @states.busy = no

        @instantiateListItems resources
        @states.busy = no

      , { skip : @states.skip }


  fetch: (query, callback, options = {}) ->

    { groupsController } = kd.singletons

    options.limit ?= @getOption 'limit'
    options.sort   = '_id' : -1

    group = groupsController.getCurrentGroup()
    group.fetchResources query, options, (err, resources) =>

      if err
        @hideLazyLoader()
        showError err, \
          KodingError : "Failed to fetch data, try again later."
        return

      callback err, resources


  loadItems: (query) ->

    @removeAllItems()
    @showLazyLoader()

    @states.skip = 0

    @states.query = query

    @fetch @states.query, (err, resources) =>

      @hideLazyLoader()
      @instantiateListItems resources


  loadView: ->

    super

    @loadItems()
    @followLazyLoad()
