{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

EmojiSelelctorVisibilityStore = require 'activity/flux/chatinput/stores/emoji/selectorvisibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelelctorVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectorVisibility : EmojiSelelctorVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['emojiSelectorVisibility']).get stateId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['emojiSelectorVisibility']).get stateId

      expect(visible).to.be.false

