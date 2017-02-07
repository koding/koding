kd                    = require 'kd'
KDView                = kd.View
kookies               = require 'kookies'
showError             = require 'app/util/showError'
KodingListView        = require './kodinglistview'
KDListItemView        = kd.ListItemView
KDListViewController  = kd.ListViewController

module.exports = class KodingListController extends KDListViewController


  constructor: (options = {}, data) ->

    if options.view and options.itemClass
      kd.warn 'The view will not be used which you passed! Because you passed view and item class together.'
      options.view  = null
    else
      options.viewOptions           ?= {}
      options.viewOptions.itemClass ?= options.itemClass

      options.view  ?= new KodingListView options.viewOptions

    options.itemClass              ?= KDListItemView

    options.loadWithScroll         ?= yes
    options.useCustomScrollView    ?= yes
    options.lazyLoadThreshold      ?= 10

    options.startWithLazyLoader    ?= yes
    options.lazyLoaderOptions     or= {}

    spinnerOptions            = options.lazyLoaderOptions.spinnerOptions or= {}
    spinnerOptions.size     or= { width : 28 }
    spinnerOptions.cssClass   = kd.utils.curry 'kodinglist-spinner', spinnerOptions.cssClass

    options.limit                  ?= 10
    options.sort                  or= { '_id' : -1 }

    options.model                 or= null
    options.fetcherMethod         or= null

    unless options.noItemFoundWidget
      options.noItemFoundText or= 'No item found!'
      options.noItemFoundWidget = new KDView
        cssClass  : 'no-item-found'
        partial   : "<cite>#{options.noItemFoundText}</cite>"

    @filterStates =
      skip        : 0
      busy        : no
      query       : options.baseQuery ? {}
      page        : 0

    super options, data

    if not options.fetcherMethod and not options.model
      return  throw new Error 'Model or fetcherMethod should be given!'

    @bindEvents()


  bindEvents: ->

    @followLazyLoad()  if @getOption 'loadWithScroll'

    listView = @getListView()

    listView
      .on 'ItemAction', ({ action, item, options }) =>
        switch action
          when 'RemoveItem'
            @removeItem item, options

          when 'ItemRemoved'
            listView.removeItem item
            @showNoItemWidget()


  removeItem: (item, options = {}) ->

    { actionMethods } = @getOptions()
    listView          = @getListView()

    confirmOptions =
      title        : options.title
      description  : options.description
      callback     : actionMethods?.remove ? ({ status, modal }) ->
        return  unless status

        item.getData().remove (err) ->
          modal.destroy()
          return showError err  if err
          listView.removeItem item


    listView.askForConfirm confirmOptions


  followLazyLoad: ->

    @on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return @hideLazyLoader()  if @filterStates.busy

      @filterStates.skip += @getOption 'limit'

      @fetch @filterStates.query, (items) =>
        @addListItems items
        @filterStates.page++
      , { skip : @filterStates.skip }


  loadItems: ->

    return  if @_inprogress
    @_inprogress = yes

    @removeAllItems()
    @showLazyLoader no

    @fetch @filterStates.query, (items) =>
      @_inprogress = no
      @emit 'ItemsLoaded', items
      return @showNoItemWidget()  unless items?.length

      @addListItems items
      @calculateAndFetchMoreIfNeeded()  if items.length is @getOption('limit')


  fetch: (query, callback, fetchOptions = {}) ->

    @filterStates.busy = yes

    { limit, fetcherMethod, model, sort } = @getOptions()

    fetchOptions.limit or= limit
    fetchOptions.sort   ?= sort

    fetcher = fetcherMethod or model.some

    fetcher query, fetchOptions, (err, items) =>

      @hideLazyLoader()
      @filterStates.busy = no

      if err
        @emit 'FetchProcessFailed', { err }
        return

      @emit 'FetchProcessSucceeded', { items }
      callback items


  loadView: ->

    super

    @loadItems()


  showNoItemWidget: ->

    super

    @filterStates.busy = no
    @emit 'NoItemWidgetShown'


  addListItems: (items = []) ->

    @instantiateListItems items  if items.length
    @filterStates.busy = no


  # Override parent class's method.
  # Don't show no item widget with this method.
  hideLazyLoader: ->

    return  unless @lazyLoader

    @lazyLoader.spinner.hide()
    @lazyLoader.hide()


  calculateAndFetchMoreIfNeeded: ->

    viewHeight = @getView().getHeight()
    listHeight = @getListView().getHeight()

    if listHeight <= viewHeight
      @lazyLoader.show()
      @emit 'LazyLoadThresholdReached'
