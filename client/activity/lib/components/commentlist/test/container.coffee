kd           = require 'kd'
expect       = require 'expect'
Container    = require '../container'
TestUtils    = require 'react-addons-test-utils'
ActivityFlux = require 'activity/flux'
immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
mock         = require '../../../../../mocks/mockingjay'

describe 'CommentListContainer', ->

  { renderIntoDocument } = TestUtils

  beforeEach ->

    @props =
      repliesCount   : 10
      onMentionClick : kd.noop
      channelId      : 'dummy-channel-id'
      messageId      : 'dummy-message-id'
      comments       : toImmutable mock.getMockMessages { size: 10 }


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render Container with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.props.repliesCount).toBeA 'number'
      expect(container.props.onMentionClick).toBeA 'function'
      expect(container.props.channelId).toEqual 'dummy-channel-id'
      expect(container.props.messageId).toEqual 'dummy-message-id'
      expect(container.props.comments instanceof immutable.Map).toBeTruthy()


    it 'should render view with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)
      viewProps = container.refs.view.props

      expect(viewProps.repliesCount).toEqual 10
      expect(viewProps.channelId).toEqual 'dummy-channel-id'
      expect(viewProps.messageId).toEqual 'dummy-message-id'
      expect(viewProps.onMentionClick).toBeA 'function'
      expect(viewProps.comments instanceof immutable.Map).toBeTruthy()


  describe '::showMoreComment', ->

    it 'should call loadComments action with correct parameters', ->

      { message }     = ActivityFlux.actions
      loadCommentsSpy = expect.spyOn message, 'loadComments'
      limit           = 10
      from            = 'dummy-createdAt-value'
      firstComment    = @props.comments.first().set 'createdAt', from
      @props.comments = @props.comments.set firstComment.get('id'), firstComment
      container       = renderIntoDocument(<Container {...@props} />)

      container.showMoreComment()

      expect(loadCommentsSpy).toHaveBeenCalledWith 'dummy-message-id', { from, limit }

