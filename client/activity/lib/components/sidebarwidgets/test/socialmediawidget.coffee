React             = require 'kd-react'
expect            = require 'expect'
TestUtils         = require 'react-addons-test-utils'
SocialMediaWidget = require '../socialmediawidget'

describe 'SocialMediaWidget', ->

	{ renderIntoDocument
	 findRenderedDOMComponentWithClass } = TestUtils

	describe '::render', ->

		it 'should rendered widget and children with correct classnames', ->

			socialmediawidget = renderIntoDocument(<SocialMediaWidget />)

			div      = findRenderedDOMComponentWithClass socialmediawidget, 'SocialMediaWidget'
			twitter  = findRenderedDOMComponentWithClass socialmediawidget, 'FeedThreadSidebar-social twitter'
			facebook = findRenderedDOMComponentWithClass socialmediawidget, 'FeedThreadSidebar-social facebook'

			expect(div).toExist()
			expect(twitter).toExist()
			expect(facebook).toExist()


		it 'should render children', ->

			socialmediawidget = renderIntoDocument(<SocialMediaWidget />)

			twitter  = findRenderedDOMComponentWithClass socialmediawidget, 'FeedThreadSidebar-social twitter'
			facebook = findRenderedDOMComponentWithClass socialmediawidget, 'FeedThreadSidebar-social facebook'

			expect(twitter.props.children).toEqual 'Koding on Twitter'
			expect(facebook.props.children).toEqual 'Koding on Facebook'