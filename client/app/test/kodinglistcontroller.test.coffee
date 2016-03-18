kd      = require 'kd'
expect  = require 'expect'

KDView  = kd.View

KodingListView       = require 'app/kodinglist/kodinglistview'
KodingListController = require 'app/kodinglist/kodinglistcontroller'


describe 'KodingListController', ->

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      {
        useCustomScrollView, lazyLoadThreshold, limit,
        sort, model, fetcherMethod
      } = listController.getOptions()

      viewInstanceCheck = listController.getListView() instanceof KodingListView

      expect(viewInstanceCheck).toBeTruthy()
      expect(useCustomScrollView).toBeTruthy()
      expect(lazyLoadThreshold).toBe 10
      expect(limit).toBe 10
      expect(model).toNotExist()
      expect(sort).toEqual { '_id' : -1 }

    it 'should create default no item found widget', ->

      listController = new KodingListController { fetcherMethod : kd.noop }

      { noItemFoundWidget, noItemFoundText } = listController.getOptions()

      expect(noItemFoundWidget).toExist()
      expect(noItemFoundText).toEqual "No item found!"

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

      spy = expect.spyOn listController, 'removeItem'

      listView.emit 'ItemAction', { action : 'RemoveItem', item }

      expect(spy).toHaveBeenCalledWith item


  describe '::followLazyLoad', ->

    it 'should call hideLazyLoader if filterState.busy is yes', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      listController.filterStates.busy = yes

      spy = expect.spyOn listController, 'hideLazyLoader'

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, -> expect(spy).toHaveBeenCalled()

    it 'should increase filterStates.skip value', ->

      listController  = new KodingListController { fetcherMethod : kd.noop, limit : 20 }

      expect(listController.filterStates.skip).toBe 0

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(listController.filterStates.skip).toBe 20

    it 'should call fetch with correct options', ->

      fetcherMethod   = (query, options, callback) -> callback null, []
      listController  = new KodingListController { fetcherMethod, limit : 20 }
      fetchSpy        = expect.spyOn listController, 'fetch'

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(fetchSpy.calls.first.arguments[0]).toEqual listController.filterStates.query
        expect(fetchSpy.calls.first.arguments[2]).toEqual { skip : listController.filterStates.skip }

    it 'should call addListItems', ->

      fetcherMethod   = (query, options, callback) -> callback null, []
      listController  = new KodingListController { fetcherMethod, limit : 20 }

      addListItemsSpy = expect.spyOn listController, 'addListItems'

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(addListItemsSpy).toHaveBeenCalled()

    it 'should increase filterStates.page value', ->

      fetcherMethod   = (query, options, callback) -> callback null, []
      listController  = new KodingListController { fetcherMethod, limit : 20 }

      expect(listController.filterStates.page).toBe 0

      listController.emit 'LazyLoadThresholdReached'

      kd.utils.wait 333, ->
        expect(listController.filterStates.page).toBe 1


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
      fetchOptions      = { limit ,sort }

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
