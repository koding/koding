kd                      = require 'kd'
React                   = require 'kd-react'
ReactDOM                = require 'react-dom'
expect                  = require 'expect'
TestUtils               = require 'react-addons-test-utils'
toImmutable             = require 'app/util/toImmutable'
ChatListItem            = require 'activity/components/chatlistitem'
ProfileText             = require 'app/components/profile/profiletext'
Avatar                  = require 'app/components/profile/avatar'
ProfileLinkContainer    = require 'app/components/profile/profilelinkcontainer'
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
ChatInputWidget         = require 'activity/components/chatinputwidget'
mockingjay              = require '../../../../mocks/mockingjay'

describe 'ChatListItem', ->

  message = toImmutable(
    mockingjay.getMockMessage 'qwerty'
  )

  messageWithEmbedData = toImmutable(
    mockingjay.getMockMessage(
      '12345'
       {
          link            :
            link_url      : 'https://www.sciencenews.org/'
            link_embed    :
              type        : 'link'
              description : 'Science News'
              title       : 'Science News'
       }
    )
  )

  editingMessage = messageWithEmbedData.set '__isEditing', yes

  describe '::render', ->

    it 'renders a chat item', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )

      accountId = message.getIn [ 'account', '_id' ]
      profileContainers = TestUtils.scryRenderedComponentsWithType result, ProfileLinkContainer
      expect(profileContainers.length).toBe 2
      expect(profileContainers[0].props.origin._id).toBe accountId
      expect(profileContainers[1].props.origin._id).toBe accountId
      expect(TestUtils.findRenderedComponentWithType result, Avatar).toExist()
      expect(TestUtils.findRenderedComponentWithType result, ProfileText).toExist()

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
      selectedItem = TestUtils.scryRenderedDOMComponentsWithClass(result, 'is-selected').first
      expect(selectedItem).toNotExist()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} isSelected=yes />
      )
      selectedItem = TestUtils.findRenderedDOMComponentWithClass result, 'is-selected'
      expect(selectedItem).toExist()


    it 'renders a chat item with menu', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} showItemMenu={no} />
      )
      menu = TestUtils.scryRenderedComponentsWithType(result, MessageItemMenu).first
      expect(menu).toNotExist()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} showItemMenu={yes} />
      )
      menu = TestUtils.findRenderedComponentWithType result, MessageItemMenu
      expect(menu.props.message).toBe message


    it 'renders a chat item with embed box', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )
      embedBox = TestUtils.scryRenderedComponentsWithType(result, EmbedBox).first
      expect(embedBox).toNotExist()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={messageWithEmbedData} />
      )
      embedBox = TestUtils.findRenderedComponentWithType result, EmbedBox
      expect(embedBox.props.data).toEqual messageWithEmbedData.get('link').toJS()


    it 'renders a chat item in edit mode', ->

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={message} />
      )
      embedExtractor = TestUtils.scryRenderedComponentsWithType(result, ChatInputEmbedExtractor).first
      expect(embedExtractor).toNotExist()

      result = TestUtils.renderIntoDocument(
        <ChatListItem message={editingMessage} channelId=1 />
      )
      embedExtractor = TestUtils.findRenderedComponentWithType result, ChatInputEmbedExtractor
      expect(embedExtractor.props.messageId).toEqual editingMessage.get 'id'
      expect(embedExtractor.props.channelId).toEqual 1
      expect(embedExtractor.props.value).toEqual editingMessage.get 'body'
      expect(embedExtractor.props.tokens).toEqual [ChannelToken, EmojiToken, MentionToken]


  describe '::onSubmit', ->

    it 'should be called when edited message is saved', ->

      props =
        message   : editingMessage
        channelId : 1
        onSubmit  : kd.noop
      spy = expect.spyOn props, 'onSubmit'

      result = TestUtils.renderIntoDocument(
        <ChatListItem {...props} />
      )

      newValue = "#{editingMessage.get('body')}!!!"

      inputWidget = TestUtils.findRenderedComponentWithType result, ChatInputWidget.Container
      inputWidget.setState { value : newValue }

      submitButton = TestUtils.findRenderedDOMComponentWithClass result, 'submit'
      TestUtils.Simulate.click submitButton

      expect(spy).toHaveBeenCalled()


  describe '::onCancelEdit', ->

    it 'should be called when message editing is cancelled', ->

      props =
        message      : editingMessage
        channelId    : 1
        onCancelEdit : kd.noop
      spy = expect.spyOn props, 'onCancelEdit'

      result = TestUtils.renderIntoDocument(
        <ChatListItem {...props} />
      )

      cancelButton = TestUtils.findRenderedDOMComponentWithClass result, 'cancel'
      TestUtils.Simulate.click cancelButton

      expect(spy).toHaveBeenCalled()


  describe '::onCloseEmbedBox', ->

    it 'should be called when embed box is closed', ->

      props =
        message         : editingMessage
        channelId       : 1
        onCloseEmbedBox : kd.noop
      spy = expect.spyOn props, 'onCloseEmbedBox'

      result = TestUtils.renderIntoDocument(
        <ChatListItem {...props} />
      )

      closeButton = TestUtils.findRenderedDOMComponentWithClass result, 'close-button'
      TestUtils.Simulate.click closeButton

      expect(spy).toHaveBeenCalled()
