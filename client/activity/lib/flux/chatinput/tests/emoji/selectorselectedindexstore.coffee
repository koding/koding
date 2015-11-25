{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

EmojiSelectorSelectedIndexStore = require 'activity/flux/chatinput/stores/emoji/selectorselectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelectorSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectorSelectedIndex : EmojiSelectorSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5
      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['emojiSelectorSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5
      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['emojiSelectorSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_EMOJI_SELECTOR_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['emojiSelectorSelectedIndex']).get stateId

      expect(selectedIndex).to.be.undefined

