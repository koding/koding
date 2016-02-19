kd        = require 'kd'
remote    = require('app/remote').getInstance()
showError = require 'app/util/showError'

AccountListViewController = require 'account/controllers/accountlistviewcontroller'


module.exports = class ResourceListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options = kd.utils.extend {}, options,
      limit               : 30
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
      query : {}


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

    callback null, [
      {title: 'WIP Resource'}
    ]


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
