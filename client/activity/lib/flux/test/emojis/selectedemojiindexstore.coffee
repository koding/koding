{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

EmojiSelectedIndexStore = require 'activity/flux/stores/emojis/selectedemojiindexstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'EmojiSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores selectedIndex : EmojiSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_SELECTED_EMOJI_INDEX, { index }
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 5
      nextIndex = index + 1

      @reactor.dispatch actionTypes.SET_SELECTED_EMOJI_INDEX, { index }
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal index
      
      @reactor.dispatch actionTypes.MOVE_TO_NEXT_EMOJI_INDEX
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 5
      prevIndex = index - 1

      @reactor.dispatch actionTypes.SET_SELECTED_EMOJI_INDEX, { index }
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal index
      
      @reactor.dispatch actionTypes.MOVE_TO_PREV_EMOJI_INDEX
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal prevIndex


  describe '#confirm', ->

    it 'confirms selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_SELECTED_EMOJI_INDEX, { index }
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal index
      expect(selectedIndex.get 'confirmed').to.be.false
      
      @reactor.dispatch actionTypes.CONFIRM_SELECTED_EMOJI_INDEX
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'confirmed').to.be.true


  describe '#reset', ->

    it 'resets selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_SELECTED_EMOJI_INDEX, { index }
      @reactor.dispatch actionTypes.CONFIRM_SELECTED_EMOJI_INDEX
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal index
      expect(selectedIndex.get 'confirmed').to.be.true

      @reactor.dispatch actionTypes.UNSET_SELECTED_EMOJI_INDEX
      selectedIndex = @reactor.evaluate ['selectedIndex']

      expect(selectedIndex.get 'index').to.equal 0
      expect(selectedIndex.get 'confirmed').to.be.false
