{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

CommonEmojiListSelectedIndexStore = require 'activity/flux/chatinput/stores/emoji/commonemojilistselectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'CommonEmojiListSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores commonEmojiListSelectedIndex : CommonEmojiListSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5
      stateId = '123'

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['commonEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5
      stateId = '123'

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['commonEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['commonEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).to.be.undefined

