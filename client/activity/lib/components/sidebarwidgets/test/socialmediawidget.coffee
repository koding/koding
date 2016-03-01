expect            = require 'expect'
TestUtils         = require 'react-addons-test-utils'
SocialMediaWidget = require '../socialmediawidget'

describe 'SocialMediaWidget', ->

  { renderIntoDocument
   findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should rendered widget and children with correct classnames', ->

      socialMediaWidget = renderIntoDocument(<SocialMediaWidget />)

      div      = findRenderedDOMComponentWithClass socialMediaWidget, 'SocialMediaWidget'
      twitter  = findRenderedDOMComponentWithClass socialMediaWidget, 'FeedThreadSidebar-social twitter'
      facebook = findRenderedDOMComponentWithClass socialMediaWidget, 'FeedThreadSidebar-social facebook'

      expect(div).toExist()
      expect(twitter).toExist()
      expect(facebook).toExist()


    it 'should render children', ->

      socialMediaWidget = renderIntoDocument(<SocialMediaWidget />)

      twitter  = findRenderedDOMComponentWithClass socialMediaWidget, 'FeedThreadSidebar-social twitter'
      facebook = findRenderedDOMComponentWithClass socialMediaWidget, 'FeedThreadSidebar-social facebook'

      expect(twitter.props.children).toEqual 'Koding on Twitter'
      expect(facebook.props.children).toEqual 'Koding on Facebook'