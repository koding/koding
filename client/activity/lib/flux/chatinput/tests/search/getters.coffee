{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputSearchStore = require 'activity/flux/chatinput/stores/search/searchstore'
ChatInputSearchSelectedIndexStore = require 'activity/flux/chatinput/stores/search/selectedindexstore'
ChatInputFlux = require 'activity/flux/chatinput'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchGetters', ->

  beforeEach ->

    @reactor = new Reactor()
    stores = {}
    stores[ChatInputSearchStore.getterPath] = ChatInputSearchStore
    stores[ChatInputSearchSelectedIndexStore.getterPath] = ChatInputSearchSelectedIndexStore
    @reactor.registerStores stores


  describe '#chatInputSearchSelectedIndex', ->

    stateId = 'test'

    it 'gets -1 when search items are empty', ->

      { getters } = ChatInputFlux
      items = []

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId
      expect(selectedIndex).to.equal -1


    it 'gets the same index which was set by action', ->

      index       = 1
      { getters } = ChatInputFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId
      expect(selectedIndex).to.equal index


    it 'handles negative store value', ->

      index       = -2
      { getters } = ChatInputFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
        { id : '4' }
        { id : '5' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId
      expect(selectedIndex).to.equal (index % items.length) + items.length

      index = -9

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId
      expect(selectedIndex).to.equal (index % items.length) + items.length


    it 'handles store value bigger than list size', ->

      index       = 5
      { getters } = ChatInputFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId
      expect(selectedIndex).to.equal index % items.length

      index = 8

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }

      selectedIndex = @reactor.evaluate getters.searchSelectedIndex stateId
      expect(selectedIndex).to.equal index % items.length


  describe '#chatInputSelectedItem', ->

    stateId = 'test'

    it 'gets item by specified selected index', ->

      index       = 1
      { getters } = ChatInputFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }

      selectedItem = @reactor.evaluateToJS getters.searchSelectedItem stateId
      expect(selectedItem.id).to.equal items[index].id

