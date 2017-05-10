debug = (require 'debug') 'kodinglist:controller'
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
      options.view ?= new (options.viewClass ? KodingListView) options.viewOptions

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

    { loadWithScroll, limit } = @getOptions()

    @followLazyLoad()  if loadWithScroll

    listView = @getListView()
    listView
      .on 'ItemAction', ({ action, item, options }) =>
        switch action
          when 'RemoveItem'
            @removeItem item, options

          when 'ItemRemoved'
            listView.removeItem item
            @showNoItemWidget()

      .on 'KeyDownOnList', @bound 'handleKeyDown'
      .on 'SelectItem', @bound 'selectItem'


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

    { limit } = @getOptions()

    @on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return @hideLazyLoader()  if @filterStates.busy

      @filterStates.skip += limit

      @fetch @filterStates.query, (items) =>
        @addListItems items
        @filterStates.page++

        if items.length is limit
          @calculateAndFetchMoreIfNeeded()

      , { skip : @filterStates.skip }


  loadItems: ->

    return  if @_inprogress
    @_inprogress = yes
    @showLazyLoader no

    @fetch @filterStates.query, (items) =>

      @replaceAllItems items
      @_inprogress = no

      if items?.length
        debug 'initial items loaded', items.length
        if items.length is @getOption 'limit'
          kd.utils.wait 1000, @bound 'calculateAndFetchMoreIfNeeded'
        @selectNextItem()
      else
        @showNoItemWidget()


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


  removeAllItems: ->

    @filterStates.skip = 0

    super


  setView: (view) ->

    super view

    view.once 'viewAppended', @bound 'loadItems'


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

    mainView   = @getView()
    listView   = @getListView()

    viewHeight = mainView.getHeight()
    listHeight = listView.getHeight()

    debug 'calculateAndFetchMoreIfNeeded', {
      listHeight, viewHeight, listView, mainView
    }

    return  if 0 in [ viewHeight, listHeight ]

    if listHeight <= viewHeight
      @lazyLoader.show()
      @emit 'LazyLoadThresholdReached'


  handleNavigation: (direction) ->

    if direction is 'down'
      @selectNextItem()
    else
      @selectPrevItem()

    [ item ] = @selectedItems
    item?.getElement().scrollIntoViewIfNeeded()


  handleKeyDown: (e) ->

    code = e.which or e.keyCode

    # for vim people; ctrl+j/k
    if e.ctrlKey
      down = 74
      up   = 75
    # for the rest of the world up/down arrows
    else
      down = 40
      up   = 38

    switch code
      when 13
        e.preventDefault()
        @emit 'ItemActivated', @selectedItems.first
      when up
        e.preventDefault()
        @handleNavigation 'up'
      when down
        e.preventDefault()
        @handleNavigation 'down'

    return yes
