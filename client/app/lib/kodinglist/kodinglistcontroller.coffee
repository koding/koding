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
      options.view ?= new KodingListView
        itemClass   : options.itemClass

    options.itemClass              ?= KDListItemView

    options.useCustomScrollView    ?= yes
    options.lazyLoadThreshold      ?= 10

    options.startWithLazyLoader    ?= yes

    options.lazyLoaderOptions     or= {}

    options.lazyLoaderOptions.spinnerOptions      or= {}
    options.lazyLoaderOptions.spinnerOptions.size or= { width : 28 }

    options.limit                  ?= 10
    options.sort                  or= { '_id' : -1 }

    options.model                 or= null
    options.fetcherMethod         or= null

    unless options.noItemFoundWidget
      options.noItemFoundText or= "No item found!"
      options.noItemFoundWidget = new KDView
        cssClass  : 'no-item-found'
        partial   : "<cite>#{options.noItemFoundText}</cite>"

    super options, data

    if not options.fetcherMethod and not options.model
      return  throw new Error 'Model or fetcherMethod should be given!'

    @filterStates =
      skip        : 0
      busy        : no
      query       : {}
      page        : 0

    @bindEvents()


  bindEvents: ->

    @followLazyLoad()

    listView = @getListView()

    # 
    # Example usage => listView.emit 'ItemAction', { action : 'RemoveItem', item : this }
    #
    listView.on 'ItemAction', ({ action, item, options }) =>
      switch action
        when 'RemoveItem'
          @removeItem item, options


  removeItem: (item, options = {}) ->

    { actionMethods } = @getOptions()
    listView          = @getListView()

    confirmOptions =
      title        : options.title
      description  : options.description
      callback     : actionMethods?.remove ? ({status, modal}) =>
        return  unless status

        item.getData().remove (err) =>
          modal.destroy()
          return showError err  if err
          listView.removeItem item
          @emit 'ItemDeleted', item


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

    @removeAllItems()
    @showLazyLoader no

    @fetch @filterStates.query, (items) =>
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


  calculateAndFetchMoreIfNeeded: ->

    viewHeight = @getView().getHeight()
    listHeight = @getListView().getHeight()

    if listHeight <= viewHeight
      @lazyLoader.show()
      @emit 'LazyLoadThresholdReached'
