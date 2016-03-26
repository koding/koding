kd                   = require 'kd'
expect               = require 'expect'
LogsItemView         = require '../views/logs/logsitemview'
KodingListView       = require 'app/kodinglist/kodinglistview'
LogsListController   = require '../views/logs/logslistcontroller'


describe 'LogsListController', ->

  afterEach -> expect.restoreSpies()


  describe '::constructor', ->

    it 'should instantiate with default options', ->

      listController = new LogsListController()

      { noItemFoundText, itemClass, viewOptions } = listController.getOptions()

      viewInstanceCheck = listController.getListView() instanceof KodingListView

      expect(viewInstanceCheck).toBeTruthy()
      expect(noItemFoundText).toEqual 'No logs found!'
      expect(itemClass).toBe LogsItemView
      expect(viewOptions.wrapper).toBeTruthy()

  describe '::getXHROptions', ->

    it 'should return object with correct endpoint', ->

      listController  = new LogsListController { scope: 'all' }
      endPoint        = '/-/api/logs'
      type            = 'GET'
      options         = listController.getXHROptions({})

      expect(options).toEqual { type, endPoint: '/-/api/logs' }

      listController  = new LogsListController { scope: 'all' }
      query           = 'dummy-query'
      options         = listController.getXHROptions { query }

      expect(options).toEqual { type, endPoint: '/-/api/logs?q=dummy-query' }

      listController  = new LogsListController { scope: 'test' }
      query           = 'dummy-query'
      options         = listController.getXHROptions { query }

      expect(options).toEqual { type, endPoint: '/-/api/logs?scope=test,q=dummy-query' }

