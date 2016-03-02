kd          = require 'kd'
expect      = require 'expect'
View        = require '../view'
immutable   = require 'immutable'
toImmutable = require 'app/util/toImmutable'
TestUtils   = require 'react-addons-test-utils'
mock        = require '../../../../../mocks/mockingjay'

describe 'CommentsView', ->

  {
    renderIntoDocument
    isCompositeComponent
    findRenderedDOMComponentWithClass } = TestUtils


  beforeEach ->

    @props =
      onMentionClick : kd.noop
      onChange       : kd.noop
      postComment    : kd.noop
      messageId      : 'dummy-message-id'
      repliesCount   : 10
      comments       : toImmutable mock.getMockMessages { size: 10 }


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render view with correct prop types', ->

      view = renderIntoDocument(<View {...@props}/>)

      expect(isCompositeComponent(view.refs.CommentList)).toBeTruthy()
      expect(isCompositeComponent(view.refs.CommentInputWidget)).toBeTruthy()
      expect(view.props.channelId).toBeA 'string'
      expect(view.props.messageId).toBeA 'string'
      expect(view.props.commentValue).toBeA 'string'
      expect(view.props.repliesCount).toEqual 10
      expect(view.props.hasValue).toBeFalsy()
      expect(view.props.onChange).toBeA 'function'
      expect(view.props.onMentionClick).toBeA 'function'
      expect(view.props.postComment).toBeA 'function'
      expect(view.props.comments instanceof immutable.Map).toBeTruthy()


    it 'should render view and its childs with correct classNames', ->

      view = renderIntoDocument(<View {...@props}/>)

      expect(findRenderedDOMComponentWithClass view, 'CommentList').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentsWrapper').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentInputWidget').toExist()
      expect(findRenderedDOMComponentWithClass view, 'FeedItem-postComment').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentInputWidget-input').toExist()


    it 'should render showMoreComments link', ->

      @props.repliesCount = 15
      view = renderIntoDocument(<View {...@props}/>)

      expect(findRenderedDOMComponentWithClass view, 'CommentList-showMoreComment').toExist()

