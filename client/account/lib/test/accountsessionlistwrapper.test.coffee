kd                        = require 'kd'
expect                    = require 'expect'
KDListView                = kd.ListView
KodingListView            = require 'app/kodinglist/kodinglistview'
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
AccountSessionListItem    = require '../accountsessionlistitem'
AccountSessionListWrapper = require '../accountsessionlistwrapper'


describe 'AccountSessionListWrapper', ->

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listWrapper    = new AccountSessionListWrapper()
      listController = listWrapper.listController
      listView       = listController.listView

      {
        useCustomScrollView, lazyLoadThreshold, limit,
        sort, model, fetcherMethod, startWithLazyLoader,
        lazyLoaderOptions, itemClass
      } = listController.getOptions()

      viewInstanceCheck       = listView instanceof KodingListView
      controllerInstanceCheck = listController instanceof KodingListController

      expect(viewInstanceCheck).toBeTruthy()
      expect(controllerInstanceCheck).toBeTruthy()
      expect(itemClass).toBe AccountSessionListItem
      expect(useCustomScrollView).toBeTruthy()
      expect(lazyLoadThreshold).toBe 8
      expect(limit).toBe 8
      expect(model).toNotExist()
      expect(startWithLazyLoader).toBeTruthy()
      expect(sort).toEqual { '_id' : -1 }
      expect(lazyLoaderOptions.spinnerOptions.size).toEqual { width : 28 }
