expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

EmojiSelectBoxSelectedIndexStore = require 'activity/flux/chatinput/stores/emoji/selectboxselectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelectBoxSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectBoxSelectedIndex : EmojiSelectBoxSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5
      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTBOX_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['emojiSelectBoxSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5
      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTBOX_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['emojiSelectBoxSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.RESET_EMOJI_SELECTBOX_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['emojiSelectBoxSelectedIndex']).get stateId

      expect(selectedIndex).toBe undefined

