kd                  = require 'kd'
expect              = require 'expect'
remote              = require('app/remote').getInstance()
SnapshotListItem    = require '../snapshotlistitem'
SnapshotsController = require '../controllers/machinesettingssnapshotscontroller'


describe 'MachineSettingsSnapshotsController', ->


  afterEach -> expect.restoreSpies()


  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listController = new SnapshotsController()

      {
        useCustomScrollView, lazyLoadThreshold, limit, itemClass,
        model, startWithLazyLoader, loadWithScroll
      } = listController.getOptions()

      expect(itemClass).toBe SnapshotListItem
      expect(model).toBe remote.api.JSnapshot
      expect(useCustomScrollView).toBeTruthy()
      expect(loadWithScroll).toBeTruthy()
      expect(lazyLoadThreshold).toBe 10
      expect(limit).toBe 10
      expect(startWithLazyLoader).toBeTruthy()


  describe '::bindEvents', ->

    it 'should call renameSnapshot method for RenameSnapshot action listener', ->

      listController = new SnapshotsController()
      listView       = listController.getListView()
      spy            = expect.spyOn listController, 'renameSnapshot'
      item           = {
        getData      : -> {
          remove     : ->
        }
      }

      listView.emit 'ItemAction', { action : 'RenameSnapshot', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should call deleteSnapshot method for DeleteSnapshot action listeners', ->

      listController = new SnapshotsController()
      listView       = listController.getListView()
      options        = { dummy: 'text' }
      spy            = expect.spyOn listController, 'confirmDeleteSnapshot'
      item           = {
        getData      : -> {
          remove     : ->
        }
      }

      listView.emit 'ItemAction', { action : 'DeleteSnapshot', item, options }

      expect(spy).toHaveBeenCalledWith item, options

    it 'should call vmFromSnapshot method for VMFromSnapshot action listener', ->

      listController = new SnapshotsController()
      listView       = listController.getListView()
      spy            = expect.spyOn listController, 'vmFromSnapshot'
      item           = {
        getData      : -> {
          remove     : ->
        }
      }

      listView.emit 'ItemAction', { action : 'VMFromSnapshot', item }

      expect(spy).toHaveBeenCalledWith item


  describe '::confirmDeleteSnapshot', ->

    it 'should call listView askForConfirm method', ->

      listController = new SnapshotsController()
      listView       = listController.getListView()
      spy            = expect.spyOn listView, 'askForConfirm'
      item           = {}
      options        = { title: 'title', description: 'description' }

      listController.confirmDeleteSnapshot item, options

      expect(spy).toHaveBeenCalled()


  describe '::deleteSnapshot', ->

    it 'should call kloud deleteSnapshot method with correct parameters', ->

      listController    = new SnapshotsController()
      machineId         = 'dummy-machineId'
      snapshotId        = 'dummy-snapshot'
      computeController = kd.getSingleton 'computeController'
      kloud             = computeController.getKloud()
      promise           = new Promise (resolve, reject) -> resolve {}
      spy               = expect.spyOn(kloud, 'deleteSnapshot').andReturn promise
      item              = {
        getData         : -> { machineId, snapshotId }
      }

      listController.deleteSnapshot item

      expect(spy).toHaveBeenCalledWith { machineId, snapshotId }


  describe '::vmFromSnapshot', ->

    it 'should emit NewVmFromSnapshot event with correct params', ->

      listController = new SnapshotsController()
      listView       = listController.getListView()
      dummyObject    = { handler: (params) -> }
      spy            = expect.spyOn dummyObject, 'handler'
      item           = {
        getData      : -> { dummy: 'text' }
      }

      listView.on 'NewVmFromSnapshot', dummyObject.handler

      listController.vmFromSnapshot item

      expect(spy).toHaveBeenCalledWith { dummy: 'text' }


  describe '::renameSnapshot', ->

    it 'should call SnapshotListItem notify with correct param', ->

      listController = new SnapshotsController()
      snapshotId     = 'dummy-snapshot'
      spy            = expect.spyOn SnapshotListItem, 'notify'
      data           = { snapshotId }
      item           = new SnapshotListItem {}, data

      item.setLabel ''

      listController.renameSnapshot item

      expect(spy).toHaveBeenCalledWith 'Name length must be larger than zero'

    it 'should call JSnapshot.one', ->

      listController = new SnapshotsController()
      { JSnapshot }  = remote.api
      snapshotId     = 'dummy-snapshot'
      spy            = expect.spyOn JSnapshot, 'one'
      data           = { snapshotId }
      item           = new SnapshotListItem {}, data

      item.setLabel 'dummy-input-value'

      listController.renameSnapshot item

      expect(spy).toHaveBeenCalled()

