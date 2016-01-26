Link                    = require 'app/components/common/link'
React                   = require 'kd-react'
expect                  = require 'expect'
ReactDOM                = require 'react-dom'
TestUtils               = require 'react-addons-test-utils'
PostingGuideLinesWidget = require '../postingguidelineswidget'

describe 'PostingGuideLinesWidget', ->

  { Simulate
   createRenderer
   renderIntoDocument
   findRenderedDOMComponentWithTag
   findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should render widget and props', ->

      postingGuideLinesWidget = renderIntoDocument(<PostingGuideLinesWidget isExpanded={ true } />)
      expect(postingGuideLinesWidget.props.isExpanded).toEqual(true)

      notPostingGuideLinesWidget = renderIntoDocument(<PostingGuideLinesWidget isExpanded={ false } />)
      expect(notPostingGuideLinesWidget.props.isExpanded).toEqual(false)


    it 'should render widget with correct class name', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<PostingGuideLinesWidget isExpanded={ true } />)

      postingGuideLinesWidget = shallowRenderer.getRenderOutput()
      expect(postingGuideLinesWidget.props.className).toEqual('ActivityGuideWidget ActivitySidebar-widget')


    it 'should render correct child value', ->

      postingGuideLinesWidget = renderIntoDocument(<PostingGuideLinesWidget isExpanded={ true } />)

      h3 = findRenderedDOMComponentWithTag postingGuideLinesWidget, 'h3'

      expect(h3.props.children).toEqual 'Posting Guidelines'


		it 'should render Link component', ->

			postingGuideLinesWidget = renderIntoDocument(<PostingGuideLinesWidget isExpanded={ true } />)

			{ children } = postingGuideLinesWidget.props

			readMeLink   = findRenderedDOMComponentWithClass postingGuideLinesWidget, 'ActivityGuideWidget-readMore'
			hideInfoLink = findRenderedDOMComponentWithClass postingGuideLinesWidget, 'ActivityGuideWidget-hideInfo'

			expect(readMeLink).toExist()
			expect(hideInfoLink).toExist()


		describe '::onClick', ->

			it 'should create action onClick to Link components and check state', ->

				event = document.createEvent 'Event'
				postingGuideLinesWidget = renderIntoDocument(<PostingGuideLinesWidget isExpanded={ false } />)

				readMeLink = ReactDOM.findDOMNode postingGuideLinesWidget.refs.ReadMore

				Simulate.click readMeLink, event
				expect(postingGuideLinesWidget.state.isExpanded).toBeTruthy()

				hideInfoLink = ReactDOM.findDOMNode postingGuideLinesWidget.refs.HideInfo
				Simulate.click hideInfoLink, event
				expect(postingGuideLinesWidget.state.isExpanded).toEqual false
