{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

SelectedChannelIdStore = require '../stores/selectedchannelidstore'
actionTypes = require '../actions/actiontypes'

describe 'SelectedChannelIdStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores selectedChannelId: SelectedChannelIdStore

  describe '#handleChangeSelectedChannel', ->

    it 'sets selected channel id to given channel id', ->

      @reactor.dispatch actionTypes.CHANGE_SELECTED_CHANNEL, { channelId: '1' }
      selectedId = @reactor.evaluate ['selectedChannelId']

      expect(selectedId).to.equal '1'

      @reactor.dispatch actionTypes.CHANGE_SELECTED_CHANNEL, { channelId: '2' }
      selectedId = @reactor.evaluate ['selectedChannelId']

      expect(selectedId).to.equal '2'


