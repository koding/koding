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

      initiatorId = '123'

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_VISIBILITY, { initiatorId, visible : yes }
      visible = @reactor.evaluate(['commonEmojiListVisibility']).get initiatorId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_COMMON_EMOJI_LIST_VISIBILITY, { initiatorId, visible : no }
      visible = @reactor.evaluate(['commonEmojiListVisibility']).get initiatorId

      expect(visible).to.be.false

