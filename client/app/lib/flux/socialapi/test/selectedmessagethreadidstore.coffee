expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

SelectedMessageThreadsIdStore = require '../stores/selectedmessagethreadidstore'
actionTypes = require '../actions/actiontypes'

describe 'SelectedMessageThreadsIdStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { selectedThreadId: SelectedMessageThreadsIdStore }

  describe '#setSelectedChannelId', ->

    it 'sets selected thread id to given channel id', ->

      @reactor.dispatch actionTypes.SET_SELECTED_MESSAGE_THREAD, { messageId: '1' }
      selectedId = @reactor.evaluate ['selectedThreadId']

      expect(selectedId).toEqual '1'

      @reactor.dispatch actionTypes.SET_SELECTED_MESSAGE_THREAD, { messageId: '2' }
      selectedId = @reactor.evaluate ['selectedThreadId']

      expect(selectedId).toEqual '2'
