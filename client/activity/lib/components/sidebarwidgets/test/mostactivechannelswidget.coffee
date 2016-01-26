mock                     = require '../../../../../mocks/mockingjay'
React                    = require 'kd-react'
expect                   = require 'expect'
immutable                = require 'immutable'
TestUtils                = require 'react-addons-test-utils'
toImmutable              = require 'app/util/toImmutable'
MostActiveChannelsWidget = require '../mostactivechannelswidget'

describe 'MostActiveChannelsWidget', ->

  { createRenderer
   renderIntoDocument
   findRenderedDOMComponentWithClass
   findRenderedDOMComponentWithTag } = TestUtils

  describe '::render', ->

    it 'should render widget  with correct classnames', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<MostActiveChannelsWidget popularChannels={ immutable.Map() }  />)

      mostactivechannelswidget = shallowRenderer.getRenderOutput()

      expect(mostactivechannelswidget.props.className).toEqual 'MostActiveChannelsWidget ActivitySidebar-widget'

    it 'should render children and fill default popularChannels ', ->

      MAX_PREVIEW_COUNT = 5

      channels = toImmutable mock.getMockChannels 10

      mostactivechannelswidget = renderIntoDocument(<MostActiveChannelsWidget popularChannels={channels}/>)

      h3  = findRenderedDOMComponentWithTag mostactivechannelswidget, 'h3'
      div = findRenderedDOMComponentWithClass mostactivechannelswidget, 'renderChannelList'

      expect(h3.props.children).toEqual 'Most active channels'
      expect(div.children.length).toEqual MAX_PREVIEW_COUNT
