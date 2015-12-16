expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

EmojiSelectBoxTabIndexStore = require 'activity/flux/chatinput/stores/emoji/selectboxtabindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelectBoxTabIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectBoxTabIndex : EmojiSelectBoxTabIndexStore


  describe '#setTabIndex', ->

    it 'sets tab index', ->

      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTBOX_TAB_INDEX, { stateId, tabIndex : 3 }
      tabIndex = @reactor.evaluate(['emojiSelectBoxTabIndex']).get stateId

      expect(tabIndex).toEqual 3

      @reactor.dispatch actions.SET_EMOJI_SELECTBOX_TAB_INDEX, { stateId, tabIndex : -1 }
      tabIndex = @reactor.evaluate(['emojiSelectBoxTabIndex']).get stateId

      expect(tabIndex).toEqual -1

