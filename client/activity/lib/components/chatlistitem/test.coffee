kd                      = require 'kd'
React                   = require 'kd-react'
ReactDOM                = require 'react-dom'
expect                  = require 'expect'
TestUtils               = require 'react-addons-test-utils'
toImmutable             = require 'app/util/toImmutable'
ChatListItem            = require 'activity/components/chatlistitem'
ProfileText             = require 'app/components/profile/profiletext'
Avatar                  = require 'app/components/profile/avatar'
MessageLink             = require 'activity/components/messagelink'
MessageTime             = require 'activity/components/chatlistitem/messagetime'
ActivityLikeLink        = require 'activity/components/chatlistitem/activitylikelink'
MessageBody             = require 'activity/components/common/messagebody'
MessageItemMenu         = require 'activity/components/messageitemmenu'
EmbedBox                = require 'activity/components/embedbox'
ChatInputEmbedExtractor = require 'activity/components/chatinputembedextractor'
ChannelToken            = require 'activity/components/chatinputwidget/tokens/channeltoken'
EmojiToken              = require 'activity/components/chatinputwidget/tokens/emojitoken'
MentionToken            = require 'activity/components/chatinputwidget/tokens/mentiontoken'

describe 'ChatListItem', ->

  message = toImmutable
    id              : 1
    body            : 'Middleweight black hole suspected near Milky Way’s center'
    interactions    : { like : { actorsCount : 1 } }
    repliesCount    : 2
    createdAt       : '2016-01-01'
    account         :
      _id           : 1
      profile       : { nickname : 'nick', firstName : '', lastName : '' }
      isIntegration : yes

  messageWithEmbedData = toImmutable
    id              : 2
    body            : 'Humans visited Arctic earlier than thought'
    interactions    : { like : { actorsCount : 4 } }
    repliesCount    : 1
    createdAt       : '2016-01-15'
    link            :
      link_embed    : 'https://www.sciencenews.org/'
      link_embed    :
        type        : 'link'
        description : 'Science News'
        title       : 'Science News'
    account         :
      _id           : 2
      profile       : { nickname : 'john', firstName : '', lastName : '' }
      isIntegration : yes

  editingMessage = toImmutable
    id              : 2
    body            : 'Humans visited Arctic earlier than thought'
    __isEditing     : yes
    interactions    : { like : { actorsCount : 4 } }
    repliesCount    : 1
    createdAt       : '2016-01-15'
    link            :
      link_embed    : 'https://www.sciencenews.org/'
      link_embed    :
        type        : 'link'
        description : 'Science News'
        title       : 'Science News'
    account         :
      _id           : 2
      profile       : { nickname : 'john', firstName : '', lastName : '' }
      isIntegration : yes


  describe '::render', ->

    it 'renders a chat item', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )

      profileText = TestUtils.findRenderedComponentWithType result, ProfileText
      expect(profileText.props.account).toEqual message.get('account').toJS()

      profileAvatar = TestUtils.findRenderedComponentWithType result, Avatar
      expect(profileAvatar.props.account).toEqual message.get('account').toJS()

      messageLink = TestUtils.findRenderedComponentWithType result, MessageLink
      expect(messageLink.props.message).toBe message

      messageTime = TestUtils.findRenderedComponentWithType messageLink, MessageTime
      expect(messageTime.props.date).toEqual message.get 'createdAt'

      likeLink = TestUtils.findRenderedComponentWithType result, ActivityLikeLink
      expect(likeLink.props.messageId).toEqual message.get 'id'
      expect(likeLink.props.interactions).toEqual message.get('interactions').toJS()

      messageBody = TestUtils.findRenderedComponentWithType result, MessageBody
      expect(messageBody.props.message).toBe message

    it 'renders selected chat item', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )
      expect(-> TestUtils.findRenderedDOMComponentWithClass result, 'is-selected').toThrow()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} isSelected=yes />
      )
      expect(TestUtils.findRenderedDOMComponentWithClass result, 'is-selected').toExist()


    it 'renders a chat item with menu', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} showItemMenu={no} />
      )
      expect(-> TestUtils.findRenderedComponentWithType result, MessageItemMenu).toThrow()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} showItemMenu={yes} />
      )
      menu = TestUtils.findRenderedComponentWithType result, MessageItemMenu
      expect(menu.props.message).toBe message


    it 'renders a chat item with embed box', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )
      expect(-> TestUtils.findRenderedComponentWithType result, EmbedBox).toThrow()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={messageWithEmbedData} />
      )
      embedBox = TestUtils.findRenderedComponentWithType result, EmbedBox
      expect(embedBox.props.data).toEqual messageWithEmbedData.get('link').toJS()


    it 'renders a chat item in edit mode', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )
      expect(-> TestUtils.findRenderedComponentWithType result, ChatInputEmbedExtractor).toThrow()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={editingMessage} channelId=1 />
      )
      inputEmbedExtractor = TestUtils.findRenderedComponentWithType result, ChatInputEmbedExtractor
      expect(inputEmbedExtractor.props.messageId).toEqual editingMessage.get 'id'
      expect(inputEmbedExtractor.props.channelId).toEqual 1
      expect(inputEmbedExtractor.props.value).toEqual editingMessage.get 'body'
      expect(inputEmbedExtractor.props.tokens).toEqual [ChannelToken, EmojiToken, MentionToken]
