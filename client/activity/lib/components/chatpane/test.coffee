kd          = require 'kd'
React       = require 'kd-react'
ReactDOM    = require 'react-dom'
expect      = require 'expect'
TestUtils   = require 'react-addons-test-utils'
toImmutable = require 'app/util/toImmutable'
ChatPane    = require './view'
ChatList    = require 'activity/components/chatlist'
ChannelInfo = require 'activity/components/channelinfo'

describe 'ChatPane', ->

  messages = toImmutable [
    {
      id              : 1
      body            : 'Will Computers Ever Truly Understand Humans?'
      interactions    : { like : { actorsCount : 1 } }
      repliesCount    : 2
      createdAt       : '2016-01-01'
      account         :
        _id           : 1
        profile       : { nickname : 'nick', firstName : '', lastName : '' }
        isIntegration : yes
    }
    {
      id              : 2
      body            : 'Brain-Computer Duel: Do We Have Free Will?'
      interactions    : { like : { actorsCount : 3 } }
      repliesCount    : 5
      createdAt       : '2016-01-01'
      account         :
        _id           : 2
        profile       : { nickname : 'john', firstName : '', lastName : '' }
        isIntegration : yes
    }
    {
      id              : 3
      body            : 'Researchers Get Remote Access to Robots'
      interactions    : { like : { actorsCount : 2 } }
      repliesCount    : 3
      createdAt       : '2016-01-15'
      account         :
        _id           : 3
        profile       : { nickname : 'alex', firstName : '', lastName : '' }
        isIntegration : yes
    }
  ]

  thread = toImmutable {
    flags                 :
      reachedFirstMessage : no
    channel               :
      id                  : 1
      name                : 'qwerty'
      unreadCount         : 1
    messages
  }

  threadWithAllLoadedMessages = toImmutable {
    flags                 :
      reachedFirstMessage : yes
    channel               :
      id                  : 2
      name                : 'qwerty'
      unreadCount         : 2
    messages
  }

  describe '::render', ->

    it 'renders ChannelInfo depending in reachedFirstMessage flag', ->

      result = TestUtils.renderIntoDocument(
        <ChatPane thread={thread} />
      )
      expect(-> TestUtils.findRenderedComponentWithType result, ChannelInfo).toThrow()

      result = TestUtils.renderIntoDocument(
        <ChatPane thread={threadWithAllLoadedMessages} />
      )

      channelInfo = TestUtils.findRenderedComponentWithType result, ChannelInfo
      expect(channelInfo).toExist()
      expect(channelInfo.props.channel).toBe threadWithAllLoadedMessages.get 'channel'

    it 'renders ChatList', ->

      result = TestUtils.renderIntoDocument(
        <ChatPane thread={thread} showItemMenu=yes isMessagesLoading=yes selectedMessageId=1 />
      )

      chatList = TestUtils.findRenderedComponentWithType result, ChatList
      expect(chatList).toExist()
      expect(chatList.props.messages).toBe thread.get 'messages'
      expect(chatList.props.channelId).toBe thread.getIn ['channel', 'id']
      expect(chatList.props.isMessagesLoading).toBe yes
      expect(chatList.props.showItemMenu).toBe yes
      expect(chatList.props.unreadCount).toBe thread.getIn ['channel', 'unreadCount']
      expect(chatList.props.selectedMessageId).toBe 1


  describe '::onInviteClick', ->

    it 'should be called when "Invite" link is clicked', ->

      props =
        thread        : threadWithAllLoadedMessages
        onInviteClick : kd.noop
      spy = expect.spyOn props, 'onInviteClick'

      result = TestUtils.renderIntoDocument(
        <ChatPane {...props} />
      )

      channelInfo = TestUtils.findRenderedComponentWithType result, ChannelInfo
      inviteLink  = TestUtils.findRenderedDOMComponentWithClass channelInfo, 'InviteOthersLink'

      TestUtils.Simulate.click inviteLink
      expect(spy).toHaveBeenCalled()
