{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

CommonEmojiListFlagsStore = require 'activity/flux/stores/emojis/commonemojilistflagsstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'CommonEmojiListFlagsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores commonEmojiListFlags : CommonEmojiListFlagsStore


  describe '#confirmSelection', ->

    it 'confirms selection', ->

      @reactor.dispatch actionTypes.CONFIRM_COMMON_EMOJI_LIST_SELECTION
      flags = @reactor.evaluate ['commonEmojiListFlags']

      expect(flags.get 'selectionConfirmed').to.be.true


  describe '#setVisibility', ->

    it 'sets visibility', ->

      @reactor.dispatch actionTypes.SET_COMMON_EMOJI_LIST_VISIBILITY, { visible : yes }
      flags = @reactor.evaluate ['commonEmojiListFlags']

      expect(flags.get 'visible').to.be.true

      @reactor.dispatch actionTypes.SET_COMMON_EMOJI_LIST_VISIBILITY, { visible : no }
      flags = @reactor.evaluate ['commonEmojiListFlags']

      expect(flags.get 'visible').to.be.false


  describe '#reset', ->

  	it 'resets flags', ->

      @reactor.dispatch actionTypes.CONFIRM_COMMON_EMOJI_LIST_SELECTION
      @reactor.dispatch actionTypes.SET_COMMON_EMOJI_LIST_VISIBILITY, { visible : yes }
      flags = @reactor.evaluate ['commonEmojiListFlags']

      expect(flags.get 'selectionConfirmed').to.be.true
      expect(flags.get 'visible').to.be.true

      @reactor.dispatch actionTypes.RESET_COMMON_EMOJI_LIST_FLAGS
      flags = @reactor.evaluate ['commonEmojiListFlags']

      expect(flags.get 'selectionConfirmed').to.be.false
      expect(flags.get 'visible').to.be.false
