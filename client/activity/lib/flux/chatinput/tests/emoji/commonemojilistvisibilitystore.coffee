{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

CommonEmojiListVisibilityStore = require 'activity/flux/chatinput/stores/emoji/commonemojilistvisibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'CommonEmojiListVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores commonEmojiListVisibility : CommonEmojiListVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['commonEmojiListVisibility']).get stateId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['commonEmojiListVisibility']).get stateId

      expect(visible).to.be.false

