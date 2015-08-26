{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputSearchStore = require 'activity/flux/stores/chatinput/chatinputsearchstore'
ChatInputSearchSelectedIndexStore = require 'activity/flux/stores/chatinput/chatinputsearchselectedindexstore'
ActivityFlux = require 'activity/flux'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputSearchGetters', ->

  beforeEach ->

    @reactor = new Reactor()
    stores = {}
    stores[ChatInputSearchStore.getterPath] = ChatInputSearchStore
    stores[ChatInputSearchSelectedIndexStore.getterPath] = ChatInputSearchSelectedIndexStore
    @reactor.registerStores stores


  describe '#chatInputSearchSelectedIndex', ->

    it 'gets -1 when search items are empty', ->

      { getters } = ActivityFlux
      items = []

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { items }

      selectedIndex = @reactor.evaluate getters.chatInputSearchSelectedIndex
      expect(selectedIndex).to.equal -1


    it 'gets the same index which was set by action', ->

      index       = 1
      { getters } = ActivityFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.chatInputSearchSelectedIndex
      expect(selectedIndex).to.equal index


    it 'handles negative store value', ->

      index       = -2
      { getters } = ActivityFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
        { id : '4' }
        { id : '5' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.chatInputSearchSelectedIndex
      expect(selectedIndex).to.equal (index % items.length) + items.length

      index = -9

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.chatInputSearchSelectedIndex
      expect(selectedIndex).to.equal (index % items.length) + items.length


    it 'handles store value bigger than list size', ->

      index       = 5
      { getters } = ActivityFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.chatInputSearchSelectedIndex
      expect(selectedIndex).to.equal index % items.length

      index = 8

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.chatInputSearchSelectedIndex
      expect(selectedIndex).to.equal index % items.length


  describe '#chatInputSelectedItem', ->

    it 'gets item by specified selected index', ->

      index       = 1
      { getters } = ActivityFlux
      items = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { items }
      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }

      selectedItem = @reactor.evaluateToJS getters.chatInputSearchSelectedItem
      expect(selectedItem.id).to.equal items[index].id

