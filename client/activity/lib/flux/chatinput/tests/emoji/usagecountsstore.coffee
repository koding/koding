{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

EmojiUsageCountsStore = require 'activity/flux/chatinput/stores/emoji/usagecountsstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiUsageCountsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiUsageCounts : EmojiUsageCountsStore


  describe '#setUsageCount', ->

    it 'sets usage count', ->

      emoji  = 'smile'
      count1 = 5
      count2 = 7

      @reactor.dispatch actions.SET_EMOJI_USAGE_COUNT, { emoji, count : count1 }
      counts = @reactor.evaluateToJS(['emojiUsageCounts'])

      expect(counts[emoji]).to.equal count1

      @reactor.dispatch actions.SET_EMOJI_USAGE_COUNT, { emoji, count : count2 }
      counts = @reactor.evaluateToJS(['emojiUsageCounts'])

      expect(counts[emoji]).to.equal count2


  describe '#incrementUsageCount', ->

    it 'increments usage count', ->

      emoji  = 'smirk'

      @reactor.dispatch actions.INCREMENT_EMOJI_USAGE_COUNT, { emoji }
      counts = @reactor.evaluateToJS(['emojiUsageCounts'])

      expect(counts[emoji]).to.equal 1

      @reactor.dispatch actions.INCREMENT_EMOJI_USAGE_COUNT, { emoji }
      counts = @reactor.evaluateToJS(['emojiUsageCounts'])

      expect(counts[emoji]).to.equal 2

