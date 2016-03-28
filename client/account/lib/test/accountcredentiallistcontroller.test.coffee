kd      = require 'kd'
mock    = require '../../../mocks/mockingjay'
expect  = require 'expect'
remote  = require('app/remote').getInstance()
Promise = require 'bluebird'

KDView  = kd.View

KodingListController            = require 'app/kodinglist/kodinglistcontroller'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'

mockCredential  = mock.getMockCredential()

modelWithData   = some  : (query, options, callback) -> callback null, [ mockCredential ]
modelWithNoData = some  : (query, options, callback) -> callback null, [ ]


describe 'AccountCredentialListController', ->

  afterEach -> expect.restoreSpies()

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listController = new AccountCredentialListController

      { limit, noItemFoundText, model } = listController.getOptions()

      expect(limit).toBe 30
      expect(noItemFoundText).toEqual "You don't have any credentials"
      expect(model).toBe remote.api.JCredential


  describe '::bindEvents', ->

    it 'should call showNoItemWidget method when ItemDeleted event is emitted', ->

      expect.spyOn AccountCredentialListController.prototype, 'showNoItemWidget'
      listController = new AccountCredentialListController
      listView       = listController.getListView()

      listView.emit 'ItemDeleted'

      expect(listController.showNoItemWidget).toHaveBeenCalled()

    it 'should listen and handle ShowItem event and call showCredential method of listView', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      fetchCredentialDataSpy = expect.spyOn(listController, 'fetchCredentialData').andCall (data, callback) ->
        callback null, mockCredential

      showCredentialSpy      = expect.spyOn listView, 'showCredential'

      listController.loadItems()

      item = listController.getListItems().first

      listView.emit 'ItemAction', { action : 'ShowItem', item }

      expect(fetchCredentialDataSpy).toHaveBeenCalled()
      expect(showCredentialSpy).toHaveBeenCalled()

    it 'should handle ShowItem event but not call showCredential method of listView', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      fetchCredentialDataSpy = expect.spyOn(listController, 'fetchCredentialData').andCall (data, callback) ->
        callback new Error 'error!', []

      showCredentialSpy      = expect.spyOn listView, 'showCredential'

      listController.loadItems()

      item = listController.getListItems().first

      listView.emit 'ItemAction', { action : 'ShowItem', item }

      expect(fetchCredentialDataSpy).toHaveBeenCalled()
      expect(showCredentialSpy).toNotHaveBeenCalled()

    it 'should handle EditItem event and call showCredentialEditModal method of listView', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      fetchCredentialDataSpy      = expect.spyOn(listController, 'fetchCredentialData').andCall (data, callback) ->
        callback null, mockCredential

      showCredentialEditModalSpy  = expect.spyOn listView, 'showCredentialEditModal'

      listController.loadItems()

      item = listController.getListItems().first

      listView.emit 'ItemAction', { action : 'EditItem', item }

      expect(fetchCredentialDataSpy).toHaveBeenCalled()
      expect(showCredentialEditModalSpy).toHaveBeenCalled()

    it 'should handle EditItem event and not call showCredentialEditModal method of listView', ->



      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      fetchCredentialDataSpy      = expect.spyOn(listController, 'fetchCredentialData').andCall (data, callback) ->
        callback new Error 'error!', []

      showCredentialEditModalSpy  = expect.spyOn listView, 'showCredentialEditModal'

      listController.loadItems()

      item = listController.getListItems().first

      listView.emit 'ItemAction', { action : 'EditItem', item }

      expect(fetchCredentialDataSpy).toHaveBeenCalled()
      expect(showCredentialEditModalSpy).toNotHaveBeenCalled()


  describe '::removeItem', ->

    it 'should not continue to work if credential is in use', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      listController.loadItems()

      item        = listController.getListItems().first
      credential  = item.getData()

      credential.inuse = yes

      item.setData credential

      spy = expect.spyOn credential, 'isBootstrapped'

      listController.removeItem item

      expect(spy).toNotHaveBeenCalled()

    # Complete this test as soon as possible!
    it 'should call askForConfirm method of listView', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      listController.loadItems()

      item        = listController.getListItems().first
      credential  = item.getData()

      credential.inuse = no

      item.setData credential

      askForConfirmSpy = expect.spyOn listView, 'askForConfirm'

      expect.spyOn(credential, 'isBootstrapped').andCall (callback) -> callback null, yes

      listController.removeItem item

      expect(askForConfirmSpy).toHaveBeenCalled()


  describe '::removeCredential', ->

    it 'should call callback and emit an event if there is no error', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      listController.loadItems()

      kallback  = expect.createSpy()
      item      = listController.getListItems().first
      spy       = expect.spyOn listView, 'emit'

      expect.spyOn(mockCredential, 'delete').andCall (callback) -> callback null

      listController.removeCredential item, kallback

      expect(kallback).toHaveBeenCalled()
      expect(spy.calls.first.arguments.first).toEqual 'ItemDeleted'


    it 'should not emit an event if any error', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      listController.loadItems()

      spy       = expect.spyOn listController, 'emit'
      item      = listController.getListItems().first

      expect.spyOn(mockCredential, 'delete').andCall (callback) -> callback new Error 'error!'

      listController.removeCredential item, kd.noop

      expect(spy).toNotHaveBeenCalled()


  describe '::destroyResources', ->

    # Complete this test as soon as possible!
    it 'should call kd.singletons.computeController.getKloud', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      listController.loadItems()

      item        = listController.getListItems().first
      credential  = item.getData()

      expect.spyOn(kd.singletons.computeController, 'getKloud').andReturn {
        bootstrap : -> new Promise (resolve) -> resolve()
      }

      listController.destroyResources credential, kd.noop

      expect(kd.singletons.computeController.getKloud).toHaveBeenCalled()


  describe '::loadItems', ->

    it 'should add required fields to query', ->

      options             =
          model           : modelWithData
          view            : listView
          provider        : 'aws'
          requiredFields  : [ 'github_username' ]

      listView        = new AccountCredentialList
      listController  = new AccountCredentialListController options

      listController.loadItems()

      { query } = listController.filterStates

      expect(query.provider).toEqual 'aws'
      expect(query.fields).toEqual options.requiredFields


  describe '::fetchCredentialData', ->

    it 'should call fetchData method of credential', ->

      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      spy = expect.spyOn mockCredential, 'fetchData'

      listController.fetchCredentialData mockCredential

      expect(spy).toHaveBeenCalled()


  describe '::filterByProvider', ->

    it 'should change filterStates\'s values', ->

      query          = { provider : 'aws' }
      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithNoData, view : listView }

      listController.filterByProvider query

      expect(listController.filterStates.skip).toBe 0
      expect(listController.filterStates.query).toEqual query

    it 'should show no item found wiget', ->

      query          = { provider : 'aws' }

      expect.spyOn AccountCredentialListController.prototype, 'showNoItemWidget'
      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithNoData, view : listView }

      listController.filterByProvider query

      expect(listController.showNoItemWidget).toHaveBeenCalled()

    it 'should add items to list', ->

      query          = { provider : 'aws' }
      listView       = new AccountCredentialList
      listController = new AccountCredentialListController { model : modelWithData, view : listView }

      spy            = expect.spyOn listController, 'addListItems'

      listController.filterByProvider query

      data = spy.calls.first.arguments.first

      expect(spy).toHaveBeenCalledWith [ mockCredential ]


  describe '::loadView', ->

    it 'should call createAddDataButton method if provider is set', ->

      listView    = new AccountCredentialList
      options     =
        model     : modelWithData
        view      : listView
        provider  : 'aws'

      expect.spyOn AccountCredentialListController.prototype, 'createAddDataButton'

      listController  = new AccountCredentialListController options

      listController.loadView new KDView

      expect(listController.createAddDataButton).toHaveBeenCalled()

    it 'should call createAddCredentialMenu method if provider is not set and dontShowCredentialMenu is not set', ->

      listView    = new AccountCredentialList
      options     =
        model     : modelWithData
        view      : listView

      expect.spyOn AccountCredentialListController.prototype, 'createAddCredentialMenu'

      listController  = new AccountCredentialListController options

      listController.loadView new KDView

      expect(listController.createAddCredentialMenu).toHaveBeenCalled()

    it 'should call not createAddCredentialMenu method if provider is not set and dontShowCredentialMenu is yes', ->

      listView    = new AccountCredentialList
      options     =
        model                   : modelWithData
        view                    : listView
        dontShowCredentialMenu  : yes

      expect.spyOn AccountCredentialListController.prototype, 'createAddCredentialMenu'

      listController  = new AccountCredentialListController options

      listController.loadView new KDView

      expect(listController.createAddCredentialMenu).toNotHaveBeenCalled()
