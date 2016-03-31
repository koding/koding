kd      = require 'kd'
mock    = require '../../mocks/mockingjay'
expect  = require 'expect'

KodingListView              = require 'app/kodinglist/kodinglistview'
KodingListController        = require 'app/kodinglist/kodinglistcontroller'

StackTemplateList           = require 'app/stacks/stacktemplatelist'
StackTemplateListItem       = require 'app/stacks/stacktemplatelistitem'
StackTemplateContentModal   = require 'app/stacks/stacktemplatecontentmodal'
StackTemplateListController = require 'app/stacks/stacktemplatelistcontroller'

item          = new StackTemplateListItem {}, mock.getMockStack()
fetcherMethod = (query, options, callback) -> callback null, [ mock.getMockJComputeStack() ]


describe 'StackTemplateListController', ->

  beforeEach -> expect.spyOn(kd.singletons.groupsController, 'getCurrentGroup').andReturn mock.getMockGroup()

  afterEach ->
    expect.restoreSpies()
    item.setData mock.getMockStack()

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView }

      { wrapper, scrollView, noItemFoundText, fetcherMethod } = listController.getOptions()

      expect(wrapper).toBeFalsy()
      expect(scrollView).toBeFalsy()
      expect(noItemFoundText).toEqual 'You currently have no stack template'
      expect(fetcherMethod).toBeA 'function'

    it 'should set slug of group to filter', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView }

      expect(listController.filterStates.query.group).toBe mock.getMockGroup().slug

    it 'should not set originId to filterStates.query if viewType is group', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, viewType : 'group' }

      expect(listController.filterStates.query.originId).toNotExist()

    it 'should set originId to filterStates.query if viewType is not group', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, viewType : 'foo' }

      expect(listController.filterStates.query.originId).toExist()


  describe '::bindEvents', ->

    it 'should handle RemoveItem event', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn listController, 'removeItem'

      listView.emit 'ItemAction', { action : 'RemoveItem', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should handle ShowItem event', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn listController, 'showItem'

      listView.emit 'ItemAction', { action : 'ShowItem', item }

      expect(spy).toHaveBeenCalled()

    it 'should handle EditItem event', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn listController, 'editItem'

      listView.emit 'ItemAction', { action : 'EditItem', item }

      expect(spy).toHaveBeenCalled()

    it 'should handle ItemSelectedAsDefault event', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn listController, 'applyToTeam'

      listView.emit 'ItemAction', { action : 'ItemSelectedAsDefault', item }

      expect(spy).toHaveBeenCalled()

    it 'should handle GenerateStack event', ->

      stackTemplate  = item.getData()
      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn listController, 'generateStack'

      listView.emit 'ItemAction', { action : 'GenerateStack', item }

      expect(spy).toHaveBeenCalled()


  describe '::applyToTeam', ->

    it 'should emit an event if config of stack is not verified', ->

      stackTemplate     = item.getData()
      listView          = new StackTemplateList
      listController    = new StackTemplateListController { view : listView, fetcherMethod }
      spy               = expect.spyOn listController, 'emit'

      stackTemplate.config.verified = no

      item.setData stackTemplate

      listController.applyToTeam item

      expect(spy.calls.first.arguments[0]).toEqual 'StackIsNotVerified'

    it 'should call groupsController.setDefaultTemplate', ->

      { groupsController } = kd.singletons

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }

      setDefaultTemplateSpy = expect.spyOn(groupsController, 'setDefaultTemplate').andCall (stackTemplate, callback) ->

      listController.applyToTeam item

      expect(setDefaultTemplateSpy.calls.first.arguments.first).toEqual item.getData()

    it 'should emit an event when setDefaultTemplate got an error', ->

      { groupsController } = kd.singletons

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }

      emitSpy               = expect.spyOn listController, 'emit'
      setDefaultTemplateSpy = expect.spyOn(groupsController, 'setDefaultTemplate').andCall (stackTemplate, callback) -> callback new Error 'error!'

      listController.applyToTeam item

      expect(emitSpy.calls.first.arguments.first).toEqual 'FailedToSetTemplate'

    it 'should call reloadStackTemplatesList method of Stacks app', ->

      { groupsController, appManager } = kd.singletons

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }

      appManagerSpy         = expect.spyOn appManager, 'tell'
      setDefaultTemplateSpy = expect.spyOn(groupsController, 'setDefaultTemplate').andCall (stackTemplate, callback) -> callback null

      listController.applyToTeam item

      expect(appManagerSpy.calls.first.arguments[0]).toEqual 'Stacks'
      expect(appManagerSpy.calls.first.arguments[1]).toEqual 'reloadStackTemplatesList'


  describe '::generateStack', ->

    it 'should call generateStack method of JStack', ->

      stackTemplate  = item.getData()
      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn stackTemplate, 'generateStack'

      listController.generateStack item

      expect(spy).toHaveBeenCalled()

    it 'should reset current stacks and call reload method', ->

      { computeController } = kd.singletons

      stackTemplate  = item.getData()
      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      resetSpy       = expect.spyOn computeController, 'reset'

      expect.spyOn(stackTemplate, 'generateStack').andCall (callback) -> callback null

      listController.generateStack item

      expect(resetSpy).toHaveBeenCalled()


  describe '::editItem', ->

    it 'should show confirm modal if stackTemplate.isDefault is yes', ->

      stackTemplate  = item.getData()
      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      spy            = expect.spyOn listView, 'askForEdit'

      stackTemplate.isDefault = no

      listController.editItem item

      expect(spy).toNotHaveBeenCalled()


  describe '::reload', ->

    it 'should call loadItems', ->

    stackTemplate  = item.getData()
    listView       = new StackTemplateList
    listController = new StackTemplateListController { view : listView, fetcherMethod }

    loadItemsSpy   = expect.spyOn listController, 'loadItems'

    listController.reload()

    expect(loadItemsSpy).toHaveBeenCalled()


  describe '::showItem', ->

    it 'should return modal that initiated from StackTemplateContentModal', ->

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }

      modal = listController.showItem item
      modal.hide()

      expect(modal).toBeA StackTemplateContentModal
      expect(modal.getData()).toBe item.getData()


  describe '::removeItem', ->

    it 'should show an error if template is in use', ->

      { groupsController, computeController } = kd.singletons

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }

      group = mock.getMockGroup()

      group.stackTemplates.push item.getData()._id

      expect.spyOn(groupsController, 'getCurrentGroup').andReturn group

      findStackFromTemplateIdSpy = expect.spyOn computeController, 'findStackFromTemplateId'

      listController.removeItem item

      expect(findStackFromTemplateIdSpy).toNotHaveBeenCalled()

    it 'should show an error if it is already generated', ->

      { groupsController, computeController } = kd.singletons

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }

      expect.spyOn(groupsController, 'getCurrentGroup').andReturn mock.getMockGroup()

      findStackFromTemplateIdSpy = expect.spyOn computeController, 'findStackFromTemplateId'

      listController.removeItem item

      expect(findStackFromTemplateIdSpy).toNotHaveBeenCalled()

    it 'should call askForConfirm method of listView with given options', ->

      { groupsController } = kd.singletons

      listView       = new StackTemplateList
      listController = new StackTemplateListController { view : listView, fetcherMethod }
      listViewSpy    = expect.spyOn listView, 'askForConfirm'

      group = mock.getMockGroup()
      group.stackTemplates = []

      expect.spyOn(groupsController, 'getCurrentGroup').andReturn group

      listController.removeItem item

      params = listViewSpy.calls.first.arguments[0]

      expect(params.title).toEqual 'Remove stack template ?'
      expect(params.description).toEqual 'Do you want to remove this stack template ?'
