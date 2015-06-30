{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

SelectedThreadIdStore = require '../stores/selectedthreadidstore'
actionTypes = require '../actions/actiontypes'

describe 'SelectedThreadIdStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores selectedThreadId: SelectedThreadIdStore

  describe '#handleChangeSelectedThread', ->

    it 'sets selected thread id to given channel id', ->

      @reactor.dispatch actionTypes.CHANGE_SELECTED_THREAD, { channelId: '1' }
      selectedId = @reactor.evaluate ['selectedThreadId']

      expect(selectedId).to.equal '1'

      @reactor.dispatch actionTypes.CHANGE_SELECTED_THREAD, { channelId: '2' }
      selectedId = @reactor.evaluate ['selectedThreadId']

      expect(selectedId).to.equal '2'


