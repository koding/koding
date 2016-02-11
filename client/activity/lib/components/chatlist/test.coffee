kd               = require 'kd'
React            = require 'kd-react'
ReactDOM         = require 'react-dom'
expect           = require 'expect'
TestUtils        = require 'react-addons-test-utils'
toImmutable      = require 'app/util/toImmutable'
ChatList         = require './index'
ChatListItem     = require 'activity/components/chatlistitem'
DateMarker       = require 'activity/components/datemarker'
Waypoint         = require 'react-waypoint'
NewMessageMarker = require 'activity/components/newmessagemarker'
mockingjay       = require '../../../../mocks/mockingjay'

describe 'ChatList', ->

  messages = toImmutable [
    mockingjay.getMockMessage('test 1', { createdAt : '2016-01-01', id : 1 })
    mockingjay.getMockMessage('test 2', { createdAt : '2016-01-15', id : 2 })
    mockingjay.getMockMessage('test 3', { createdAt : '2016-01-15', id : 3 })
  ]

  describe '::render', ->

    it 'renders messages', ->

      result = TestUtils.renderIntoDocument(
        <ChatList messages={messages} showItemMenu=yes selectedMessageId={messages.last().get 'id'} />
      )
      items  = TestUtils.scryRenderedComponentsWithType result, ChatListItem

      expect(items.length).toEqual messages.size
      for item, i in items
        expect(item.props.message).toBe messages.get i
        expect(item.props.showItemMenu).toBe yes
      expect(items.last.props.isSelected).toBe yes


    it 'renders date markers', ->

      result = TestUtils.renderIntoDocument(
        <ChatList messages={messages} showItemMenu=yes selectedMessageId={messages.last().get 'id'} />
      )
      items  = TestUtils.scryRenderedComponentsWithType result, DateMarker

      expect(items.length).toEqual 2
      expect(items.first.props.date).toEqual messages.first().get 'createdAt'
      expect(items[1].props.date).toEqual messages.last().get 'createdAt'


    it 'renders unread message marker', ->

      result = TestUtils.renderIntoDocument(
        <ChatList messages={messages} />
      )
      newMessageMarker = TestUtils.scryRenderedComponentsWithType(result, NewMessageMarker).first
      expect(newMessageMarker).toNotExist()
      waypoint = TestUtils.scryRenderedComponentsWithType(result, Waypoint).first
      expect(waypoint).toNotExist()

      result = TestUtils.renderIntoDocument(
        <ChatList messages={messages} unreadCount=1 />
      )
      newMessageMarker = TestUtils.findRenderedComponentWithType result, NewMessageMarker
      expect(newMessageMarker).toExist()
      waypoint = TestUtils.findRenderedComponentWithType result, Waypoint
      expect(waypoint).toExist()

  describe '::resize', ->

    it 'should call updateDateMarkersPosition when page is resized', ->

      result = TestUtils.renderIntoDocument(
        <ChatList />
      )

      spyResize = expect.spyOn result, 'updateDateMarkersPosition'

      window.dispatchEvent new Event 'resize'

      expect(spyResize).toHaveBeenCalled()


    it 'should not have been called after component will unmount called ', ->

      div = document.createElement('div');

      result = React.render(<ChatList />, div)

      spyResize = expect.spyOn result, 'updateDateMarkersPosition'

      React.unmountComponentAtNode div

      window.dispatchEvent new Event 'resize'

      expect(spyResize).toNotHaveBeenCalled()


