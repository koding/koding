kd      = require 'kd'
expect  = require 'expect'

KDView          = kd.View
KDListView      = kd.ListView
KDListItemView  = kd.ListItemView

KodingListView       = require 'app/kodinglist/kodinglistview'
KodingListController = require 'app/kodinglist/kodinglistcontroller'


describe 'KodingListController', ->

  afterEach ->

    expect.restoreSpies()


  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      {
        useCustomScrollView, lazyLoadThreshold, limit,
        sort, model, fetcherMethod, startWithLazyLoader,
        lazyLoaderOptions, loadWithScroll
      } = listController.getOptions()

      viewInstanceCheck = listController.getListView() instanceof KodingListView

      expect(viewInstanceCheck).toBeTruthy()
      expect(useCustomScrollView).toBeTruthy()
      expect(loadWithScroll).toBeTruthy()
      expect(lazyLoadThreshold).toBe 10
      expect(limit).toBe 10
      expect(model).toNotExist()
      expect(startWithLazyLoader).toBeTruthy()
      expect(sort).toEqual { '_id' : -1 }
      expect(lazyLoaderOptions.spinnerOptions.size).toEqual { width : 28 }

    it 'should create lazyLoader with kodinglist-spinner css class', ->

      listController = new KodingListController { fetcherMethod : kd.noop }
      listController.createLazyLoader()

      expect(listController.lazyLoader.spinner.hasClass 'kodinglist-spinner').toBeTruthy()

    it 'should use KDListView despite of given view option with itemClass', ->

      listController  = new KodingListController
        view          : new KodingListView
        itemClass     : KDListItemView
        fetcherMethod : kd.noop

      viewInstanceCheck = listController.getListView() instanceof KodingListView

      expect(viewInstanceCheck).toBeFalsy()

    it 'should use given view option', ->

      listController  = new KodingListController
        view          : new KodingListView
        fetcherMethod : kd.noop

      viewInstanceCheck = listController.getListView() instanceof KodingListView

      expect(viewInstanceCheck).toBeTruthy()

    it 'should create default no item found widget', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      { noItemFoundWidget, noItemFoundText } = listController.getOptions()

      expect(noItemFoundWidget).toExist()
      expect(noItemFoundText).toEqual 'No item found!'

    it 'should create no item found widget with given text', ->

      noItemFoundText = "You don't have any custom events."
      listController  = new KodingListController { noItemFoundText, fetcherMethod : kd.noop }

      expect(listController.getOptions().noItemFoundText).toEqual noItemFoundText

    it 'should create no item found widget with given KDView element', ->

      cssClass  = 'custom-no-item-found-widget'

      noItemFoundWidget = new KDView { cssClass, fetcherMethod : kd.noop }

      listController    = new KodingListController { noItemFoundWidget, fetcherMethod : kd.noop }
      listController.putNoItemView()

      expect(listController.noItemView.hasClass(cssClass)).toBeTruthy()

    it 'should check filter state\'s values', ->

      listController    = new KodingListController { fetcherMethod : kd.noop }

      { skip, busy, query, page } = listController.filterStates

      expect(skip).toEqual 0
      expect(busy).toBeFalsy()
      expect(query).toEqual {}
      expect(page).toEqual 0

    it 'should pass view options to KodingListView\'s view', ->

      viewOptions     =
        cssClass      : 'test-listview'

      listController  = new KodingListController { fetcherMethod : kd.noop, viewOptions }
      listView        = listController.getListView()

      expect(listView.hasClass('test-listview')).toBeTruthy()


    it 'should thrown an error for ungiven model and fetcherMethod', ->

      expect(-> new KodingListController).toThrow /Model or fetcherMethod should be given!/


  describe '::bindEvents', ->

    it 'should listen all "ItemAction" events', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      listView        = listController.getListView()
      item            = {
        getData       : -> {
          remove      : ->
        }
      }

      spy     = expect.spyOn listController, 'removeItem'
      options = { title: 'Remove item ?' }

      listView.emit 'ItemAction', { action : 'RemoveItem', item, options }

      expect(spy).toHaveBeenCalledWith item, options

    it 'should call showNoItemWidget method when ItemDeleted event is emitted', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      listView        = listController.getListView()
      spy             = expect.spyOn listController, 'showNoItemWidget'

      listView.emit 'ItemAction', { action : 'ItemRemoved' }

      expect(spy).toHaveBeenCalled()

    it 'should remove item from list view when ItemDeleted event is emitted', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      listView        = listController.getListView()
      spy             = expect.spyOn listView, 'removeItem'

      listView.emit 'ItemAction', { action : 'ItemRemoved' }

      expect(spy).toHaveBeenCalled()


  describe '::followLazyLoad', ->

    it 'should call hideLazyLoader if filterState.busy is yes', (done) ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      listController.filterStates.busy = yes

      spy = expect.spyOn listController, 'hideLazyLoader'

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(spy).toHaveBeenCalled()
        done()

    it 'should increase filterStates.skip value', (done) ->

      listController  = new KodingListController { fetcherMethod : kd.noop, limit : 20 }

      expect(listController.filterStates.skip).toBe 0

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(listController.filterStates.skip).toBe 20
        done()

    it 'should call followLazyLoad if loadWithScroll is yes', ->

      expect.spyOn KodingListController.prototype, 'followLazyLoad'

      listController  = new KodingListController
        fetcherMethod  : kd.noop

      expect(listController.followLazyLoad).toHaveBeenCalled()

    it 'should not call followLazyLoad if loadWithScroll is no', ->

      expect.spyOn KodingListController.prototype, 'followLazyLoad'

      listController  = new KodingListController
        fetcherMethod  : kd.noop
        loadWithScroll : no

      expect(listController.followLazyLoad).toNotHaveBeenCalled()

    it 'should call fetch with correct options', (done) ->

      fetcherMethod   = (query, options, callback) -> callback null, []
      listController  = new KodingListController { fetcherMethod, limit : 20 }
      fetchSpy        = expect.spyOn listController, 'fetch'

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(fetchSpy.calls.first.arguments[0]).toEqual listController.filterStates.query
        expect(fetchSpy.calls.first.arguments[2]).toEqual { skip : listController.filterStates.skip }
        done()

    it 'should call addListItems', (done) ->

      fetcherMethod   = (query, options, callback) -> callback null, []
      listController  = new KodingListController { fetcherMethod, limit : 20 }

      addListItemsSpy = expect.spyOn listController, 'addListItems'

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(addListItemsSpy).toHaveBeenCalled()
        done()

    it 'should increase filterStates.page value', (done) ->

      fetcherMethod   = (query, options, callback) -> callback null, []
      listController  = new KodingListController { fetcherMethod, limit : 20 }

      expect(listController.filterStates.page).toBe 0

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(listController.filterStates.page).toBe 1
        done()


  describe '::loadItems', ->

    it 'should call removeAllItems', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }

      spy = expect.spyOn listController, 'removeAllItems'

      listController.loadItems()

      expect(spy).toHaveBeenCalled()

    it 'should call showLazyLoader', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      spy = expect.spyOn listController, 'showLazyLoader'

      listController.loadItems()

      expect(spy).toHaveBeenCalled()

    it 'should call fetch', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      spy = expect.spyOn(listController, 'fetch').andCallThrough()

      listController.loadItems()

      expect(spy).toHaveBeenCalled()

    it 'should show no item widget', ->

      fetcherMethod = (query, options, callback) -> callback null, []

      listController = new KodingListController { fetcherMethod }

      fetchSpy = expect.spyOn(listController, 'fetch').andCallThrough()
      showNoItemWidgetSpy = expect.spyOn(listController, 'showNoItemWidget')

      listController.loadItems()

      expect(fetchSpy).toHaveBeenCalled()
      expect(showNoItemWidgetSpy).toHaveBeenCalled()

    it 'should call addListItems', ->

      items = [ 'kodinguser', 'kodinguser2' ]

      fetcherMethod = (query, options, callback) -> callback null, items

      listController = new KodingListController { fetcherMethod }

      fetchSpy          = expect.spyOn(listController, 'fetch').andCallThrough()
      addListItemsSpy   = expect.spyOn listController, 'addListItems'

      listController.loadItems()

      expect(fetchSpy).toHaveBeenCalled()
      expect(addListItemsSpy).toHaveBeenCalledWith items

    it 'should call calculateAndFetchMoreIfNeeded', ->

      items = [ 'kodinguser', 'kodinguser2', 'kodinguser3' ]

      fetcherMethod = (query, options, callback) -> callback null, items

      listController = new KodingListController { fetcherMethod, limit : 3 }

      fetchSpy = expect.spyOn(listController, 'fetch').andCallThrough()
      calculateAndFetchMoreIfNeededSpy = expect.spyOn(listController, 'calculateAndFetchMoreIfNeeded')

      listController.loadItems()

      expect(fetchSpy).toHaveBeenCalled()
      expect(calculateAndFetchMoreIfNeededSpy).toHaveBeenCalled()

    it 'should emit "ItemsLoaded" event', ->

      items         = [ 'kodinguser', 'kodinguser2' ]
      fetcherMethod = (query, options, callback) -> callback null, items

      listController = new KodingListController { fetcherMethod }
      emitSpy        = expect.spyOn listController, 'emit'

      listController.loadItems()

      targetEvent    = emitSpy.calls.filter (c) -> c.arguments.first is 'ItemsLoaded'

      expect(targetEvent[0].arguments[0]).toEqual 'ItemsLoaded'
      expect(targetEvent[0].arguments[1]).toEqual items


  describe '::showNoItemWidget', ->

    it 'should set no to filterStates.busy', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      listController.showNoItemWidget()
      expect(listController.filterStates.busy).toBeFalsy()


  describe '::addListItems', ->

    it 'should add items to list', ->

      items           = [ 'kodinguser', 'kodinguser2', 'kodinguser3' ]
      listController  = new KodingListController { fetcherMethod : kd.noop }

      spy = expect.spyOn listController, 'instantiateListItems'

      listController.addListItems items

      expect(spy).toHaveBeenCalledWith items
      expect(listController.filterStates.busy).toBeFalsy()

    it 'should not call instantiateListItems', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }

      spy = expect.spyOn listController, 'instantiateListItems'

      listController.addListItems()

      expect(spy).toNotHaveBeenCalled()


  describe '::fetch', ->

    it 'should check limit and sort if fetchOptions is not set', ->

      fetcherMethodSpy  = expect.createSpy()
      listController    = new KodingListController { fetcherMethod : fetcherMethodSpy }

      { limit, sort }   = listController.getOptions()
      fetchOptions      = { limit, sort }

      listController.fetch {}, kd.noop

      expect(fetcherMethodSpy.calls.first.arguments[0]).toEqual {}
      expect(fetcherMethodSpy.calls.first.arguments[1]).toEqual fetchOptions

    it 'should call hideLazyLoader', ->

      fetcherMethod   = (query, options, callback) -> callback null, []

      listController  = new KodingListController { fetcherMethod }

      hideLazyLoaderSpy = expect.spyOn listController, 'hideLazyLoader'

      listController.fetch {}, kd.noop

      expect(hideLazyLoaderSpy).toHaveBeenCalled()

    it 'should set no to filterStates.busy', ->

      fetcherMethod   = (query, options, callback) -> callback null, []

      listController  = new KodingListController { fetcherMethod }

      listController.fetch {}, kd.noop

      expect(listController.filterStates.busy).toBeFalsy()

    it 'should set no to filterStates.busy when got an error', ->

      err             = new Error 'Failed!'
      fetcherMethod   = (query, options, callback) -> callback err, []

      listController  = new KodingListController { fetcherMethod }
      callbackSpy     = expect.createSpy()

      listController.fetch {}, callbackSpy

      expect(callbackSpy).toNotHaveBeenCalled()

    it 'should call given callback', ->

      fetcherMethod   = (query, options, callback) -> callback null, []

      listController  = new KodingListController { fetcherMethod }
      callbackSpy     = expect.createSpy()

      listController.fetch {}, callbackSpy

      expect(callbackSpy).toHaveBeenCalled()

    it 'should call some method of given model', ->

      SessionModel    = ->
        some          : -> (query, options, callback) -> callback null, []

      session         = new SessionModel
      listController  = new KodingListController { model : session }

      spy = expect.spyOn session, 'some'

      listController.fetch {}, kd.noop

      expect(spy).toHaveBeenCalled()


  describe '::calculateAndFetchMoreIfNeeded', ->

    it 'should continue to fetch items', (done) ->

      items           = [ 'kodinguser', 'kodinguser2', 'kodinguser3', 'kodinguser4', 'kodinguser5' ]

      fetcherMethod   = (query, options, callback) ->
        limit   = if not options.skip then 1 else options.limit + 1
        result  = items.slice (options.skip or 0), limit
        callback null, result

      listController  = new KodingListController { fetcherMethod, limit : 1 }

      listController.getView().setHeight 500
      listController.getListView().setHeight 300

      listController.loadItems()

      kd.utils.wait 333, ->
        { length } = listController.getListView().items
        expect(length).toBeGreaterThan 1
        done()


  describe '::hideLazyLoader', ->

    it 'should not call showNoItemWidget method', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      spy             = expect.spyOn listController, 'showNoItemWidget'

      listController.hideLazyLoader()

      expect(spy).toNotHaveBeenCalled()
