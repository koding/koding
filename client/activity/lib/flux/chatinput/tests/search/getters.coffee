expect  = require 'expect'
Reactor = require 'app/flux/base/reactor'
React   = require 'kd-react'

ChatInputSearchStore = require 'activity/flux/chatinput/stores/search/searchstore'
ChatInputFlux = require 'activity/flux/chatinput'
DropboxSettingsStore = require 'activity/flux/chatinput/stores/dropboxsettingsstore'

actionTypes = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchGetters', ->

  searchItems = [
    { id : '1', name : 'message 1' }
    { id : '2', name : 'message 2' }
    { id : '3', name : 'message 3' }
  ]

  stateId = '123'
  config  = {
    component       : React.Component
    getters         :
      items         : 'dropboxSearchItems'
      selectedIndex : 'searchSelectedIndex'
      selectedItem  : 'searchSelectedItem'
  }
  testConfig = {
    component       : React.Component
    getters         :
      items         : 'dropboxTestItems'
      selectedIndex : 'testSelectedIndex'
      selectedItem  : 'testSelectedItem'
  }

  beforeEach ->

    @reactor = new Reactor()
    stores = {}
    stores[ChatInputSearchStore.getterPath] = ChatInputSearchStore
    stores[DropboxSettingsStore.getterPath] = DropboxSettingsStore
    @reactor.registerStores stores

    @reactor.dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items : searchItems }


  describe '#dropboxSearchItems', ->

    it 'returns nothing if drobox config doesn\'t contain dropboxSearchItems getter', ->

      { getters } = ChatInputFlux

      items = @reactor.evaluate getters.dropboxSearchItems stateId
      expect(items).toBeA 'undefined'

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config : testConfig }

      items = @reactor.evaluate getters.dropboxSearchItems stateId
      expect(items).toBeA 'undefined'


    it 'returns loaded items if dropbox config contain dropboxSearchItems getters', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config }

      items = @reactor.evaluateToJS getters.dropboxSearchItems stateId
      expect(items).toEqual searchItems


  describe '#searchSelectedIndex', ->

    it 'returns -1 if search items are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config : testConfig }
      index = @reactor.evaluate getters.searchSelectedIndex stateId

      expect(index).toBe -1


    it 'returns 0 by default', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config }
      index = @reactor.evaluate getters.searchSelectedIndex stateId

      expect(index).toBe 0


    it 'returns index which was set before', ->

      index = 1
      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId

      expect(selectedIndex).toBe index


    it 'returns index corrected to items size if index is greater that items size', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config }

      items = @reactor.evaluate getters.dropboxSearchItems stateId

      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : items.size - 1 }
      @reactor.dispatch actionTypes.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId

      expect(selectedIndex).toBe 0


    it 'returns index corrected to items size if index is negative', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config }
      # index is set by default to 0
      @reactor.dispatch actionTypes.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }

      items = @reactor.evaluate getters.dropboxSearchItems stateId
      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId

      expect(selectedIndex).toBe items.size - 1


  describe '#searchSelectedItem', ->

    it 'returns nothing if search items are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config : testConfig }
      selectedItem = @reactor.evaluate getters.searchSelectedItem stateId

      expect(selectedItem).toBeA 'undefined'


    it 'returns item by selected index', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'test', config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : 1 }

      selectedItem = @reactor.evaluateToJS getters.searchSelectedItem stateId

      expect(selectedItem).toEqual searchItems[1]

