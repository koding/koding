kd                   = require 'kd'
expect               = require 'expect'
KodingListView       = require 'app/kodinglist/kodinglistview'
APITokenListView     = require '../views/api/apitokenlistview'
APITokenItemView     = require '../views/api/apitokenitemview'
KodingListController = require 'app/kodinglist/kodinglistcontroller'

describe 'APITokenListView', ->

  afterEach -> expect.restoreSpies()

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      APITokenListWrapper = new APITokenListView
      listController   = APITokenListWrapper.listController

      cssClass = APITokenListWrapper.getOption 'cssClass'

      { limit, loadWithScroll } = listController.getOptions()

      expect(cssClass).toEqual 'members-commonview'
      expect(loadWithScroll).toBeFalsy()
      expect(limit).toBe 20


    it 'should instantiate with default controller, view and listitem instances', ->

      APITokenListWrapper = new APITokenListView
      listController      = APITokenListWrapper.listController
      listView            = listController.getListView()

      cssClass  = APITokenListWrapper.getOption 'cssClass'
      itemClass = listController.getOption 'itemClass'

      viewInstanceCheck       = listView instanceof KodingListView
      controllerInstanceCheck = listController instanceof KodingListController

      expect(viewInstanceCheck).toBeTruthy()
      expect(itemClass).toBe APITokenItemView
      expect(controllerInstanceCheck).toBeTruthy()

