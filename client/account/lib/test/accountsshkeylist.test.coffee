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
