kd                  = require 'kd'
React               = require 'kd-react'
ReactDOM            = require 'react-dom'
expect              = require 'expect'
TestUtils           = require 'react-addons-test-utils'
UnreadMessagesLabel = require '../unreadmessageslabel'
ScrollablePosition  = require 'activity/constants/scrollableposition'

describe 'ChatPaneUnreadMessagesLabel', ->

  describe '::render', ->

    it 'renders nothing if unread count is 0', ->

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel unreadCount={0} />
      )

      expect(result.props.children).toNotExist()

    it 'renders unread count label if unread count > 0', ->

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel unreadCount={1} />
      )

      counterText = TestUtils.findRenderedDOMComponentWithClass result, 'counterText'
      expect(counterText.props.children).toEqual '1 new message'

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel unreadCount={3} />
      )

      counterText = TestUtils.findRenderedDOMComponentWithClass result, 'counterText'
      expect(counterText.props.children).toEqual '3 new messages'

    it 'adds a proper css class depending on position', ->

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel unreadCount={1} unreadMessagePosition={ScrollablePosition.ABOVE} />
      )

      container = TestUtils.findRenderedDOMComponentWithClass result, 'ChatPane-unreadMessages'
      expect(container.classList.contains 'fixedOnTop').toBe yes

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel unreadCount={1} unreadMessagePosition={ScrollablePosition.BELOW} />
      )

      container = TestUtils.findRenderedDOMComponentWithClass result, 'ChatPane-unreadMessages'
      expect(container.classList.contains 'fixedOnBottom').toBe yes

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel unreadCount={1} unreadMessagePosition={ScrollablePosition.INSIDE} />
      )

      container = TestUtils.findRenderedDOMComponentWithClass result, 'ChatPane-unreadMessages'
      expect(container.classList.contains 'out').toBe yes


  describe '::onJump', ->

    it 'should be called when clicking on component', ->

      props = { unreadCount : 3, onJump : kd.noop }
      spy   = expect.spyOn props, 'onJump'

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel {...props} />
      )

      container = TestUtils.findRenderedDOMComponentWithClass result, 'ChatPane-unreadMessages'
      TestUtils.Simulate.click container

      expect(spy).toHaveBeenCalled()


  describe '::onMarkAsRead', ->

    it 'should be called when clicking on "Mark As Read" button', ->

      props = { unreadCount : 3, onMarkAsRead : kd.noop }
      spy   = expect.spyOn props, 'onMarkAsRead'

      result = TestUtils.renderIntoDocument(
        <UnreadMessagesLabel {...props} />
      )

      button = TestUtils.findRenderedDOMComponentWithClass result, 'markAsRead'
      TestUtils.Simulate.click button

      expect(spy).toHaveBeenCalled()
