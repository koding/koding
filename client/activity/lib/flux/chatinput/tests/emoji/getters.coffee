expect  = require 'expect'
Reactor = require 'app/flux/base/reactor'
React   = require 'kd-react'

ChatInputFlux        = require 'activity/flux/chatinput'
actionTypes          = require 'activity/flux/chatinput/actions/actiontypes'
DropboxSettingsStore = require 'activity/flux/chatinput/stores/dropboxsettingsstore'
EmojisStore          = require 'activity/flux/chatinput/stores/emoji/emojisstore'


describe 'ChatInputEmojiGetters', ->

  stateId = '123'
  config  = {
    component       : React.Component
    getters         :
      items         : 'dropboxEmojis'
      selectedIndex : 'emojisSelectedIndex'
      selectedItem  : 'emojisSelectedItem'
  }
  testConfig = {
    component       : React.Component
    getters         :
      items         : 'dropboxTestItems'
      selectedIndex : 'testSelectedIndex'
      selectedItem  : 'testSelectedItem'
  }

  beforeEach ->

    @reactor = new Reactor
    stores   = {}
    stores[EmojisStore.getterPath] = EmojisStore
    stores[DropboxSettingsStore.getterPath] = DropboxSettingsStore
    @reactor.registerStores stores


  describe '#dropboxEmojis', ->

    it 'returns nothing if drobox config doesn\'t contain dropboxEmojis getter', ->

      { getters } = ChatInputFlux

      items = @reactor.evaluate getters.dropboxEmojis stateId
      expect(items).toBeA 'undefined'

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config : testConfig }

      items = @reactor.evaluate getters.dropboxEmojis stateId
      expect(items).toBeA 'undefined'


    it 'returns nothing if drobox config contain dropboxEmojis getter but query is empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : '', config }

      items = @reactor.evaluate getters.dropboxEmojis stateId
      expect(items).toBeA 'undefined'


    it 'returns emojis filtered by query if query isn\'t empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config }
      items = @reactor.evaluateToJS getters.dropboxEmojis stateId

      expect(items).toEqual ['apple', 'green_apple', 'pineapple']

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'z', config }
      items = @reactor.evaluateToJS getters.dropboxEmojis stateId

      expect(items).toEqual ['zap', 'zero', 'zzz']


  describe '#emojisSelectedIndex', ->

    it 'returns -1 if emojis are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config : testConfig }
      index = @reactor.evaluate getters.emojisSelectedIndex stateId

      expect(index).toBe -1


    it 'returns 0 by default', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config }
      index = @reactor.evaluate getters.emojisSelectedIndex stateId

      expect(index).toBe 0


    it 'returns index which was set before', ->

      index = 1
      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.emojisSelectedIndex stateId

      expect(selectedIndex).toBe index


    it 'returns index corrected to items size if index is greater that items size', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config }

      items = @reactor.evaluate getters.dropboxEmojis stateId

      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : items.size - 1 }
      @reactor.dispatch actionTypes.MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }

      selectedIndex = @reactor.evaluate getters.emojisSelectedIndex stateId

      expect(selectedIndex).toBe 0


    it 'returns index corrected to items size if index is negative', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config }
      # index is set by default to 0
      @reactor.dispatch actionTypes.MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }

      items = @reactor.evaluate getters.dropboxEmojis stateId
      selectedIndex = @reactor.evaluate getters.emojisSelectedIndex stateId

      expect(selectedIndex).toBe items.size - 1


  describe '#emojisSelectedItem', ->

    it 'returns nothing if emojis are empty', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config : testConfig }
      selectedItem = @reactor.evaluate getters.emojisSelectedItem stateId

      expect(selectedItem).toBeA 'undefined'


    it 'returns item by selected index', ->

      { getters } = ChatInputFlux

      @reactor.dispatch actionTypes.SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query : 'apple', config }
      @reactor.dispatch actionTypes.SET_DROPBOX_SELECTED_INDEX, { stateId, index : 1 }

      selectedItem = @reactor.evaluateToJS getters.emojisSelectedItem stateId

      expect(selectedItem).toEqual 'green_apple'

