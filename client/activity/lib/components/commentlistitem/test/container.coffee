kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
expect       = require 'expect'
Container    = require '../container'
View         = require '../view'
TestUtils    = require 'react-addons-test-utils'
ActivityFlux = require 'activity/flux'
immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
mock         = require '../../../../../mocks/mockingjay'

describe 'CommentListItemContainer', ->


  { renderIntoDocument } = TestUtils

  { channel, message } = ActivityFlux.actions

  beforeEach ->

    @props =
      onMentionClick : kd.noop
      channelId      : 'dummy-channel-id'
      comment        : toImmutable mock.getMockMessage()


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'renders Container with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.props.channelId).toEqual 'dummy-channel-id'
      expect(container.props.onMentionClick).toBeA 'function'
      expect(container.props.comment instanceof immutable.Map).toBeTruthy()


    it 'should render view with correct props', ->

      container = renderIntoDocument(<Container {...@props} />)
      viewProps = container.refs.view.props

      expect(viewProps.hasValue).toBeTruthy()
      expect(viewProps.commentValue).toEqual ''
      expect(viewProps.onClick).toBeA 'function'
      expect(viewProps.onChange).toBeA 'function'
      expect(viewProps.cancelEdit).toBeA 'function'
      expect(viewProps.updateComment).toBeA 'function'
      expect(viewProps.comment instanceof immutable.Map).toBeTruthy()


  describe '::onChange', ->

    it 'should update commentValue and hasValue states', ->

      container = renderIntoDocument(<Container {...@props} />)

      event = { target : { value : 'dummy-value' } }

      container.onChange event

      expect(container.state.hasValue).toBeTruthy()
      expect(container.state.commentValue).toEqual 'dummy-value'


  describe '::cancelEdit', ->

    it 'should call unsetMessageEditMode action with correct parameters and set correct commentValue state', ->

      { comment } = @props

      comment          = comment.set '_id', 'dummy-comment-id'
      @props.comment   = comment.set 'body', 'dummy-value'
      unsetEditModeSpy = expect.spyOn message, 'unsetMessageEditMode'
      container        = renderIntoDocument(<Container {...@props} />)

      container.cancelEdit()

      expect(container.state.commentValue).toEqual 'dummy-value'
      expect(unsetEditModeSpy).toHaveBeenCalledWith 'dummy-comment-id', 'dummy-channel-id'


  describe '::updateComment', ->

    it 'should call unsetMessageEditMode and editMessage message actions with correct parameters', ->

      { comment } = @props

      comment          = comment.set '_id', 'dummy-comment-id'
      @props.comment   = comment.set 'body', 'dummy-value'
      editMessageSpy   = expect.spyOn message, 'editMessage'
      unsetEditModeSpy = expect.spyOn message, 'unsetMessageEditMode'
      container        = renderIntoDocument(<Container {...@props} />)

      container.updateComment()

      expect(editMessageSpy).toHaveBeenCalledWith 'dummy-comment-id', 'dummy-value'
      expect(unsetEditModeSpy).toHaveBeenCalledWith 'dummy-comment-id', 'dummy-channel-id'


  describe '::onClick', ->

    it 'should call passed onMentionClick handler', ->

      onMentionClickSpy = expect.createSpy()

      container   = renderIntoDocument(<Container {...@props} onMentionClick={onMentionClickSpy}/>)

      container.onClick()

      expect(onMentionClickSpy).toHaveBeenCalledWith @props.comment

