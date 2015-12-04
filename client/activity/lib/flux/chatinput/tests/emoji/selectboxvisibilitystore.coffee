{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

EmojiSelectBoxVisibilityStore = require 'activity/flux/chatinput/stores/emoji/selectboxvisibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelectBoxVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectBoxVisibility : EmojiSelectBoxVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTBOX_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['emojiSelectBoxVisibility']).get stateId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_EMOJI_SELECTBOX_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['emojiSelectBoxVisibility']).get stateId

      expect(visible).to.be.false

