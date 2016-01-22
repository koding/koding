kd          = require 'kd'
React       = require 'kd-react'
ReactDOM    = require 'react-dom'
expect      = require 'expect'
View        = require '../view'
immutable   = require 'immutable'
toImmutable = require 'app/util/toImmutable'
TestUtils   = require 'react-addons-test-utils'
mock        = require '../../../../../mocks/mockingjay'


describe 'CommentListItemView', ->

  {
    Simulate
    renderIntoDocument
    findRenderedDOMComponentWithClass } = TestUtils


  beforeEach ->

    @props =
      cancelEdit    : kd.noop
      onClick       : kd.noop
      onChange      : kd.noop
      updateComment : kd.noop
      comment       : toImmutable mock.getMockMessage()


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render view with correct prop types', ->

      view = renderIntoDocument(<View {...@props}/>)

      expect(view.props.cancelEdit).toBeA 'function'
      expect(view.props.onClick).toBeA 'function'
      expect(view.props.onChange).toBeA 'function'
      expect(view.props.updateComment).toBeA 'function'
      expect(view.props.comment instanceof immutable.Map).toBeTruthy()


    it 'should render view with classNames', ->

      view = renderIntoDocument(<View {...@props}/>)

      expect(findRenderedDOMComponentWithClass view, 'CommentListItem').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentListItem-date').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentListItem-body').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentListItem-footer').toExist()


    it 'should render correct text content', ->

      @props.comment = @props.comment.set 'body', 'dummy-comment-body'

      view = renderIntoDocument(<View {...@props}/>)
      node = findRenderedDOMComponentWithClass view, 'MessageBody'

      expect(node.textContent).toEqual 'dummy-comment-body'


    it 'should render view editing className', ->

      @props.comment = @props.comment.set '__isEditing', yes

      view = renderIntoDocument(<View {...@props}/>)

      expect(findRenderedDOMComponentWithClass view, 'editing').toExist()


    it 'should render view with edited classname', ->

      today     = new Date()
      yesterday = today.setDate today.getDate() - 1

      @props.comment = @props.comment.set 'updatedAt', today
      @props.comment = @props.comment.set 'createdAt', yesterday

      view = renderIntoDocument(<View {...@props}/>)

      expect(findRenderedDOMComponentWithClass view, 'edited').toExist()


  describe '::onClick', ->

    it 'should call passed onClick handler', ->

      onClickSpy = expect.createSpy()
      view = renderIntoDocument(<View {...@props} onClick={onClickSpy}/>)
      node = ReactDOM.findDOMNode view.refs.MentionLink

      Simulate.click node

      expect(onClickSpy).toHaveBeenCalled()
