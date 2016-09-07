kd      = require 'kd'
expect  = require 'expect'

KodingListController                = require 'app/kodinglist/kodinglistcontroller'
AccountLinkedAccountsListController = require 'account/views/accountlinkedaccountslistcontroller'


describe 'AccountLinkedAccountsListController', ->

  describe 'constructor', ->

    it 'should be extended from KodingListController', ->

      listController  = new AccountLinkedAccountsListController

      expect(listController).toBeA KodingListController

    it 'should has fetcherMethod option', ->

      listController    = new AccountLinkedAccountsListController
      { fetcherMethod } = listController.getOptions()

      expect(fetcherMethod).toBeA 'function'
