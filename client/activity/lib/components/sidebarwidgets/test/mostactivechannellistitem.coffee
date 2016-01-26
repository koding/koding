mock                      = require '../../../../../mocks/mockingjay'
React                     = require 'kd-react'
expect                    = require 'expect'
ReactDOM                  = require 'react-dom'
TestUtils                 = require 'react-addons-test-utils'
immutable                 = require 'immutable'
toImmutable               = require 'app/util/toImmutable'
ActivityFlux              = require 'activity/flux'
MostActiveChannelListItem = require '../mostactivechannellistitem'

describe 'MostActiveChannelListItem', ->

  { Simulate
   createRenderer
   renderIntoDocument
   findRenderedDOMComponentWithTag } = TestUtils

  describe '::render', ->

    it 'should render widget with correct class name', ->

      options = { typeConstant : 'bot' }
      channel = toImmutable(mock.getMockChannel options)

      shallowRenderer = createRenderer()
      shallowRenderer.render(<MostActiveChannelListItem channel={channel}/>)

      mostActiveChannelListItem = shallowRenderer.getRenderOutput()

      expect(mostActiveChannelListItem.props.className).toEqual 'MostActiveChannelItem'

    it 'should render children with correct class name for isParticipant true', ->

      options = { typeConstant : 'bot' }
      channel = toImmutable(mock.getMockChannel options)

      mostActiveChannelListItem = renderIntoDocument(<MostActiveChannelListItem channel={channel} />)

      button = findRenderedDOMComponentWithTag mostActiveChannelListItem, 'Button'

      expect(button.props.className).toInclude('following')


    it 'should render children with correct class name for isParticipant false', ->

      options = { typeConstant : 'bot' }
      channel = toImmutable(mock.getMockChannel options)
      channel = channel.set 'isParticipant', false

      mostActiveChannelListItem = renderIntoDocument(<MostActiveChannelListItem channel={channel} />)

      button = findRenderedDOMComponentWithTag mostActiveChannelListItem, 'Button'

      expect(button.props.className).toExclude('following')


  describe '::onClick', ->

    it 'should create action for unfollowChannel with correct channel id on onClick event', ->

      { channel } = ActivityFlux.actions
      spy     = expect.spyOn channel, 'unfollowChannel'

      options = { typeConstant : 'bot' }
      channel = toImmutable(mock.getMockChannel options)

      event = document.createEvent 'Event'
      mostActiveChannelListItem = renderIntoDocument(<MostActiveChannelListItem channel={channel} />)

      button = findRenderedDOMComponentWithTag mostActiveChannelListItem, 'Button'

      Simulate.click button, event

      expect(spy).toHaveBeenCalledWith channel.get 'id'


    it 'should create action for followChannel with correct channel id on onClick event', ->

      { channel } = ActivityFlux.actions
      spy = expect.spyOn channel, 'followChannel'

      options = { typeConstant : 'bot' }
      channel = toImmutable(mock.getMockChannel options)
      channel = channel.set 'isParticipant', false

      event = document.createEvent 'Event'
      mostActiveChannelListItem = renderIntoDocument(<MostActiveChannelListItem channel={channel} />)

      button = findRenderedDOMComponentWithTag mostActiveChannelListItem, 'Button'

      Simulate.click button, event

      expect(spy).toHaveBeenCalledWith channel.get 'id'
