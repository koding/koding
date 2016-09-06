expect       = require 'expect'
ChannelToken = require 'activity/components/chatinputwidget/tokens/channeltoken'
EmojiToken   = require 'activity/components/chatinputwidget/tokens/emojitoken'
MentionToken = require 'activity/components/chatinputwidget/tokens/mentiontoken'
SearchToken  = require 'activity/components/chatinputwidget/tokens/searchtoken'
CommandToken = require 'activity/components/chatinputwidget/tokens/commandtoken'

describe 'ChatInputWidget.Tokens', ->

  describe 'Channel query extraction', ->

    it 'extracts nothing from plain text', ->
      query = ChannelToken.extractQuery 'test'
      expect(query).toEqual undefined

    it 'extracts channel when current position is within or at the end of channel name', ->
      query = ChannelToken.extractQuery 'hey #koding'
      expect(query).toEqual 'koding'
      query = ChannelToken.extractQuery 'hey #koding whoa!', 11
      expect(query).toEqual 'koding'

    it 'extracts nothing when current word is not channel even if the whole text contains channel', ->
      query = ChannelToken.extractQuery 'hey #koding how are things?'
      expect(query).toEqual undefined

    it 'extracts empty string when current position is at the very beginning of channel name', ->
      query = ChannelToken.extractQuery 'hey #koding whoa!', 5
      expect(query).toEqual ''

    it 'extracts nothing when channel is within code block', ->
      query = ChannelToken.extractQuery '```hey @koding whoa!```', 14
      expect(query).toEqual undefined


  describe 'Emoji query extraction', ->

    it 'extracts nothing from plain text', ->
      query = EmojiToken.extractQuery 'test'
      expect(query).toEqual undefined

    it 'extracts emoji when current position is within or at the end of emoji name', ->
      query = EmojiToken.extractQuery 'test :smile'
      expect(query).toEqual 'smile'
      query = EmojiToken.extractQuery 'test :smile qwerty', 11
      expect(query).toEqual 'smile'

    it 'extracts nothing when current word is not emoji even if the whole text contains emoji', ->
      query = EmojiToken.extractQuery 'test :smile qwerty'
      expect(query).toEqual undefined

    it 'extracts nothing when current position is at the very beginning of emoji name', ->
      query = EmojiToken.extractQuery 'test :smile qwerty', 6
      expect(query).toEqual undefined

    it 'extracts nothing when emoji is within code block', ->
      query = EmojiToken.extractQuery '```test :smile qwerty```', 14
      expect(query).toEqual undefined


  describe 'Mention query extraction', ->

    it 'extracts nothing from plain text', ->
      query = MentionToken.extractQuery 'test'
      expect(query).toEqual undefined

    it 'extracts mention when current position is within or at the end of mention name', ->
      query = MentionToken.extractQuery 'ping @nick'
      expect(query).toEqual 'nick'
      query = MentionToken.extractQuery 'ping @nick wake up!', 10
      expect(query).toEqual 'nick'

    it 'extracts nothing when current word is not mention even if the whole text contains mention', ->
      query = MentionToken.extractQuery 'ping @nick can you reply?'
      expect(query).toEqual undefined

    it 'extracts empty string when current position is at the very beginning of mention name', ->
      query = MentionToken.extractQuery 'ping @nick wake up!!', 6
      expect(query).toEqual ''

    it 'extracts nothing when mention is within code block', ->
      query = MentionToken.extractQuery '```ping @nick wake up!```', 10
      expect(query).toEqual undefined


  describe 'Search query extraction', ->

    it 'extracts nothing from plain text', ->
      query = SearchToken.extractQuery 'test'
      expect(query).toEqual undefined

    it 'extracts query when text starts with /search', ->
      query = SearchToken.extractQuery '/search test'
      expect(query).toEqual 'test'

    it 'extracts query when text starts with /s', ->
      query = SearchToken.extractQuery '/s test'
      expect(query).toEqual 'test'

    it 'extracts nothing when text doesn\'t start with /s or /search', ->
      query = SearchToken.extractQuery '/sss test'
      expect(query).toEqual undefined
      query = SearchToken.extractQuery 'qwerty /search test'
      expect(query).toEqual undefined


  describe 'Command query extraction', ->

    it 'extracts nothing from plain text', ->
      query = CommandToken.extractQuery 'test'
      expect(query).toEqual undefined

    it 'extracts query when text starts with /', ->
      query = CommandToken.extractQuery '/invite'
      expect(query).toEqual '/invite'

    it 'extracts nothing when text starts with / but the second character is whitespace', ->
      query = CommandToken.extractQuery '/  search'
      expect(query).toEqual undefined
