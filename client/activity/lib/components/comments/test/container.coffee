kd          = require 'kd'
React       = require 'kd-react'
expect      = require 'expect'
Container   = require '../container'
TestUtils   = require 'react-addons-test-utils'
immutable   = require 'immutable'
toImmutable = require 'app/util/toImmutable'
mock        = require '../../../../../mocks/mockingjay'


describe 'CommentsContainer', ->

  { renderIntoDocument } = TestUtils

  beforeEach ->

    @props =
      channelId : 'dummy-channel-id'
      message   : toImmutable mock.getMockMessage()


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render Container with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.props.channelId).toEqual 'dummy-channel-id'
      expect(container.props.message instanceof immutable.Map).toBeTruthy()


    it 'should render view with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)
      viewProps = container.refs.view.props

      expect(viewProps.channelId).toEqual 'dummy-channel-id'
      expect(viewProps.hasValue).toBeFalsy()
      expect(viewProps.commentValue).toEqual ''
      expect(viewProps.postComment).toBeA 'function'
      expect(viewProps.onChange).toBeA 'function'
      expect(viewProps.onMentionClick).toBeA 'function'
      expect(viewProps.comments instanceof immutable.List).toBeTruthy()


  describe '::handleCommentInputChange', ->

    it 'should update commentValue and hasValue states', ->

      container = renderIntoDocument(<Container {...@props} />)

      event = { target : { value : 'dummy-value' } }

      container.handleCommentInputChange event

      expect(container.state.hasValue).toBeTruthy()
      expect(container.state.commentValue).toEqual 'dummy-value'


  describe '::getComments', ->

    it 'should get sorted comments by createdAt', ->

      anyDay                 = "2016-01-22T23:07:23.757Z"
      theDayBeforeAnyDay     = "2016-01-21T23:07:23.757Z"

      firstComment           = mock.getMockMessage()
      firstComment.body      = 'first comment'
      firstComment.createdAt = anyDay

      lastComment            = mock.getMockMessage()
      lastComment.body       = 'last comment'
      lastComment.createdAt  = theDayBeforeAnyDay

      @props.message.comments = immutable.List()
      @props.message = @props.message.setIn ['comments', '1'], toImmutable firstComment
      @props.message = @props.message.setIn ['comments', '2'], toImmutable lastComment

      container = renderIntoDocument(<Container {...@props} />)

      comments = container.getComments()

      expect(comments.last().get 'body').toEqual 'first comment'
      expect(comments.first().get 'body').toEqual 'last comment'

