{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

CommonEmojiListSelectedIndexStore = require 'activity/flux/stores/chatinput/commonemojilistselectedindexstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'CommonEmojiListSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores commonEmojiListSelectedIndex : CommonEmojiListSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['commonEmojiListSelectedIndex']

      expect(selectedIndex).to.equal index


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['commonEmojiListSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actionTypes.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX
      selectedIndex = @reactor.evaluate ['commonEmojiListSelectedIndex']

      expect(selectedIndex).to.equal 0
