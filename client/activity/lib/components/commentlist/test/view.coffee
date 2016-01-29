kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
expect       = require 'expect'
View         = require '../view'
TestUtils    = require 'react-addons-test-utils'
immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
mock         = require '../../../../../mocks/mockingjay'

describe 'CommentListView', ->

  { Simulate
    renderIntoDocument
    findRenderedDOMComponentWithClass
    scryRenderedDOMComponentsWithClass } = TestUtils


  beforeEach ->

    @props =
      repliesCount    : 15
      onMentionClick  : kd.noop
      showMoreComment : kd.noop
      channelId       : 'dummy-channel-id'
      comments        : toImmutable mock.getMockMessages { size: 10 }


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render View with correct props', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(view.props.repliesCount).toEqual 15
      expect(view.props.onMentionClick).toBeA 'function'
      expect(view.props.showMoreComment).toBeA 'function'
      expect(view.props.channelId).toEqual 'dummy-channel-id'
      expect(view.props.comments instanceof immutable.Map).toBeTruthy()


    it 'should render View with correct classNames', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(findRenderedDOMComponentWithClass view, 'CommentList').toExist()
      expect((scryRenderedDOMComponentsWithClass view, 'CommentListItem').length).toEqual 10
      expect(findRenderedDOMComponentWithClass view, 'CommentList-showMoreComment').toExist()


  describe '::onClick', ->

    it 'should call passed showMoreComment handler when click the showMoreComment link', ->

      showMoreSpy = expect.createSpy()
      view        = renderIntoDocument(<View {...@props} showMoreComment={showMoreSpy}/>)
      node        = ReactDOM.findDOMNode view
      showMoreEl  = node.querySelector '.CommentList-showMoreComment'

      Simulate.click showMoreEl

      expect(showMoreSpy).toHaveBeenCalled()

