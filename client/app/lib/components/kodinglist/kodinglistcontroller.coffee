kd                    = require 'kd'
KDView                = kd.View
kookies               = require 'kookies'
showError             = require 'app/util/showError'
KodingListView        = require './kodinglistview'
KDListViewController  = kd.ListViewController


module.exports = class KodingListController extends KDListViewController


  constructor: (options = {}, data) ->

    options.view                   ?= new KodingListView delegate : this

    options.useCustomScrollView    ?= yes
    options.lazyLoadThreshold      ?= 10

    options.limit                  ?= 10
    options.sort                  or= { '_id' : -1 }

    options.model                 or= null
    options.type                  or= '' # etc. machine, group, account, session
    options.fetcherMethod         or= null

    unless options.noItemFoundWidget
      options.noItemFoundText or= "You don't have any #{options.type}"
      options.noItemFoundWidget = new KDView
        cssClass  : 'no-item-found'
        partial   : "<cite>#{options.noItemFoundText}</cite>"

    super options, data

    if not options.fetcherMethod and not options.model
      err = new Error 'Model is not found!'
      @emit 'KodingListControllerCanNotWork', { err }
      kd.error err
      return

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
    listView.on 'ItemAction', ({ action, item }) =>
      switch action
        when 'RemoveItem'
          @removeItem item


  removeItem: (item) ->

    { type }  = @getOptions()
    listView  = @getListView()

    confirmOptions =
      type         : type
      callback     : ({status, modal}) =>
        if status
          item.getData().remove (err) =>
            modal.destroy()
            return showError err  if err
            listView.removeItem item
            @emit 'ItemDeleted', item


    listView.askForConfirm confirmOptions


  editItem: ->


  followLazyLoad: ->

    @on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return @hideLazyLoader()  if @filterStates.busy

      @filterStates.busy  = yes
      @filterStates.skip += @getOption 'limit'

      @fetch @filterStates.query, (items) =>
        @addListItems items
        @filterStates.page++
      , { skip : @filterStates.skip }


  loadItems: (options = {}) ->

    @removeAllItems()
    @showLazyLoader()

    @fetch @filterStates.query, (items) =>
      return @showNoItemWidget()  unless items?.length

      @addListItems items
      @calculateAndFetchMoreIfNeeded()  if items.length is @getOption('limit')

    , options


  fetch: (query, callback, fetchOptions = {}) ->

    { limit, fetcherMethod, model, sort } = @getOptions()

    fetchOptions.limit or= limit
    fetchOptions.sort  or= sort

    fetcher = if fetcherMethod then fetcherMethod else model.some

    fetcher @filterStates.query, fetchOptions, (err, items) =>

      @hideLazyLoader()

      if err
        @emit 'FetchProcessFailed', { err }
        @filterStates.busy = no
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
