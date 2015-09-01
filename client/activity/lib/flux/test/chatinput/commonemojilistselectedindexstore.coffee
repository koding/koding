{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

CommonEmojiListSelectedIndexStore = require 'activity/flux/stores/chatinput/commonemojilistselectedindexstore'
actions = require 'activity/flux/actions/actiontypes'

describe 'CommonEmojiListSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores commonEmojiListSelectedIndex : CommonEmojiListSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5
      initiatorId = '123'

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }
      selectedIndex = @reactor.evaluate(['commonEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal index


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5
      initiatorId = '123'

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }
      selectedIndex = @reactor.evaluate(['commonEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX, { initiatorId }
      selectedIndex = @reactor.evaluate(['commonEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.be.undefined

