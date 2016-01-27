kd          = require 'kd'
React       = require 'kd-react'
ReactDOM    = require 'react-dom'
expect      = require 'expect'
TestUtils   = require 'react-addons-test-utils'
toImmutable = require 'app/util/toImmutable'
ChatPane    = require './view'
ChatList    = require 'activity/components/chatlist'
ChannelInfo = require 'activity/components/channelinfo'
mockingjay  = require '../../../../mocks/mockingjay'


describe 'ChatPane', ->

  thread = toImmutable mockingjay.getMockThread { channelId : 1 }
  thread = thread.setIn [ 'channel', 'unreadCount' ], 1
  threadWithFlags = toImmutable mockingjay.getMockThread { channelId : 2, flags : { reachedFirstMessage : yes } }

  describe '::render', ->

    it 'renders ChannelInfo depending in reachedFirstMessage flag', ->

      result = TestUtils.renderIntoDocument(
        <ChatPane thread={thread} />
      )
      channelInfo = TestUtils.scryRenderedComponentsWithType(result, ChannelInfo).first
      expect(channelInfo).toNotExist()

      result = TestUtils.renderIntoDocument(
        <ChatPane thread={threadWithFlags} />
      )

      channelInfo = TestUtils.findRenderedComponentWithType result, ChannelInfo
      expect(channelInfo).toExist()
      expect(channelInfo.props.channel).toBe threadWithFlags.get 'channel'

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
        thread        : threadWithFlags
        onInviteClick : kd.noop
      spy = expect.spyOn props, 'onInviteClick'

      result = TestUtils.renderIntoDocument(
        <ChatPane {...props} />
      )

      channelInfo = TestUtils.findRenderedComponentWithType result, ChannelInfo
      inviteLink  = TestUtils.findRenderedDOMComponentWithClass channelInfo, 'InviteOthersLink'

      TestUtils.Simulate.click inviteLink
      expect(spy).toHaveBeenCalled()
