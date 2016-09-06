expect                     = require 'expect'
TestUtils                  = require 'react-addons-test-utils'
ActivityAnnouncementWidget = require '../activityannouncementwidget'

describe 'ActivityAnnouncementWidget', ->

  { renderIntoDocument
   findRenderedDOMComponentWithClass
   findRenderedDOMComponentWithTag } = TestUtils

  describe '::render', ->

    it 'should render widget and children with correct classnames', ->

      activityAnnouncementWidget = renderIntoDocument(<ActivityAnnouncementWidget />)

      mainDiv  = findRenderedDOMComponentWithClass activityAnnouncementWidget, 'AnnouncementWidget ActivitySidebar-widget'
      childDiv = findRenderedDOMComponentWithClass activityAnnouncementWidget, 'AnnouncementWidget-icon'

      expect(mainDiv).toExist()
      expect(childDiv).toExist()


    it 'should render children with correct values', ->

      activityAnnouncementWidget = renderIntoDocument(<ActivityAnnouncementWidget />)

      h3 = findRenderedDOMComponentWithTag activityAnnouncementWidget, 'h3'
      p  = findRenderedDOMComponentWithTag activityAnnouncementWidget, 'p'
      a  = findRenderedDOMComponentWithTag activityAnnouncementWidget, 'a'

      expect(p.props.children).toEqual 'Win over $150,000 in cash prizes! Hack from wherever you are!'
      expect(h3.props.children).toEqual 'New: Koding Hackathon is Back!'
      expect(a.props.children).toEqual 'Apply Now, space limited!'
