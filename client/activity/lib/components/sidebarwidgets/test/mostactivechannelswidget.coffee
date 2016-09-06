mock                     = require '../../../../../mocks/mockingjay'
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

      mostActiveChannelsWidget = shallowRenderer.getRenderOutput()

      expect(mostActiveChannelsWidget.props.className).toEqual 'MostActiveChannelsWidget ActivitySidebar-widget'


    it 'should render children and fill default popularChannels ', ->

      MAX_PREVIEW_COUNT = 5

      channels = toImmutable mock.getMockChannels 10

      mostActiveChannelsWidget = renderIntoDocument(<MostActiveChannelsWidget popularChannels={channels}/>)

      h3  = findRenderedDOMComponentWithTag mostActiveChannelsWidget, 'h3'
      div = findRenderedDOMComponentWithClass mostActiveChannelsWidget, 'renderChannelList'

      expect(h3.props.children).toEqual 'Most active channels'
      expect(div.children.length).toEqual MAX_PREVIEW_COUNT
