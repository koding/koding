kd                    = require 'kd'
expect                = require 'expect'
KodingListView        = require 'app/kodinglist/kodinglistview'
AccountSshKeyList     = require 'account/accountsshkeylist'
AccountSshKeyListItem = require 'account/accountsshkeylist'


describe 'AccountSSHKeyList', ->

  describe 'constructor', ->

    it 'should be extended from KodingListView', ->

      listView      = new AccountSshKeyList
      instanceCheck = listView instanceof KodingListView

      expect(instanceCheck).toBeTruthy()

    it 'should be a <ul> HTML element', ->

      listView = new AccountSshKeyList

      expect(listView.getOptions().tagName).toEqual 'ul'


  describe '::sendItemAction', ->

    it 'should emit an event with given parameters', ->

      listView = new AccountSshKeyList
      spy      = expect.spyOn listView, 'emit'

      listView.sendItemAction 'EditItem', { item : 'test' }

      expect(spy.calls.first.arguments[0]).toEqual        'ItemAction'
      expect(spy.calls.first.arguments[1].item).toEqual   'test'
      expect(spy.calls.first.arguments[1].action).toEqual 'EditItem'
