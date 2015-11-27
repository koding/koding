{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

EmojiSelectorTabIndexStore = require 'activity/flux/chatinput/stores/emoji/selectortabindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelectorTabIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectorTabIndex : EmojiSelectorTabIndexStore


  describe '#setTabIndex', ->

    it 'sets tab index', ->

      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_TAB_INDEX, { stateId, tabIndex : 3 }
      tabIndex = @reactor.evaluate(['emojiSelectorTabIndex']).get stateId

      expect(tabIndex).to.equal 3

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_TAB_INDEX, { stateId, tabIndex : -1 }
      tabIndex = @reactor.evaluate(['emojiSelectorTabIndex']).get stateId

      expect(tabIndex).to.equal -1

