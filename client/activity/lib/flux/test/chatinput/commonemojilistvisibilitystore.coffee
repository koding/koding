{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

CommonEmojiListVisibilityStore = require 'activity/flux/stores/chatinput/commonemojilistvisibilitystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'CommonEmojiListVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores commonEmojiListVisibility : CommonEmojiListVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_VISIBILITY, { visible : yes }
      visible = @reactor.evaluate ['commonEmojiListVisibility']

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_VISIBILITY, { visible : no }
      visible = @reactor.evaluate ['commonEmojiListVisibility']

      expect(visible).to.be.false

