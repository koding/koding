kd        = require 'kd'
remote    = require('app/remote').getInstance()
showError = require 'app/util/showError'

AccountListViewController = require 'account/controllers/accountlistviewcontroller'


module.exports = class TeamListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options = kd.utils.extend {}, options,
      limit               : 30
      noItemFoundText     : 'No teams found!'
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

      @fetch @states.query, (err, teams) =>

        @hideLazyLoader()

        if err or not teams
          return @states.busy = no

        @instantiateListItems teams
        @states.busy = no

      , { skip : @states.skip }


  fetch: (query, callback, options = {}) ->

    { JGroup } = remote.api

    options.limit ?= @getOption 'limit'
    options.sort   = '_id' : -1

    JGroup.someWithRelationship query, options, (err, teams) =>

      if err
        @hideLazyLoader()
        showError err, \
          KodingError : "Failed to fetch data, try again later."
        return

      callback err, teams


  loadItems: (slug) ->

    @removeAllItems()
    @showLazyLoader()

    @states.skip = 0

    query = {
      slug: { $nin: ['koding', 'guests'] }
    }

    if slug
      query.slug.$in = [ slug ]

    @states.query = query

    @fetch @states.query, (err, teams) =>

      @hideLazyLoader()
      @instantiateListItems teams


  loadView: ->

    super

    @loadItems()
    @followLazyLoad()
