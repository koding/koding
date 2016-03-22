kd      = require 'kd'
expect  = require 'expect'

KodingListController                = require 'app/kodinglist/kodinglistcontroller'
AccountLinkedAccountsListController = require 'account/views/accountlinkedaccountslistcontroller'


describe 'AccountLinkedAccountsListController', ->

  describe 'constructor', ->

    it 'should be extended from KodingListController', ->

      listController  = new AccountLinkedAccountsListController
      instanceCheck   = listController instanceof KodingListController

      expect(instanceCheck).toBeTruthy()

    it 'should has fetcherMethod option', ->

      listController    = new AccountLinkedAccountsListController
      { fetcherMethod } = listController.getOptions()

      expect(fetcherMethod).toBeA 'function'
