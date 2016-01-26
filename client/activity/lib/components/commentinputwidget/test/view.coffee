kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
expect       = require 'expect'
View         = require '../view'
TestUtils    = require 'react-addons-test-utils'
KeyboardKeys = require 'app/constants/keyboardKeys'

describe 'CommentInputWidgetView', ->

  { Simulate
    renderIntoDocument
    findRenderedDOMComponentWithClass } = TestUtils

  beforeEach ->

    @props =
      hasValue     : yes
      onChange     : kd.noop
      onKeyDown    : kd.noop
      onFocus      : kd.noop
      onBlur       : kd.noop
      postComment  : kd.noop
      commentValue : 'dummy-comment-value'


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'renders container with correct props and state', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(view.props.hasValue).toBeTruthy()
      expect(view.props.onChange).toBeA 'function'
      expect(view.props.onKeyDown).toBeA 'function'
      expect(view.props.onBlur).toBeA 'function'
      expect(view.props.onFocus).toBeA 'function'
      expect(view.props.postComment).toBeA 'function'
      expect(view.props.commentValue).toEqual 'dummy-comment-value'


    it 'renders container with correct props and state', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(findRenderedDOMComponentWithClass view, 'green').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentInputWidget').toExist()
      expect(findRenderedDOMComponentWithClass view, 'CommentInputWidget-input').toExist()
      expect(findRenderedDOMComponentWithClass view, 'FeedItem-postComment').toExist()


    it 'should render postComment button with hidden className', ->

      @props.hasValue     = no
      @props.focusOnInput = no

      view = renderIntoDocument(<View {...@props} />)
      node = findRenderedDOMComponentWithClass view, 'FeedItem-postComment'

      expect(node.className).toContain 'hidden'


  describe '::onFocus', ->

    it 'should set call passed onFocus handler', ->

      onFocusSpy = expect.createSpy()
      view       = renderIntoDocument(<View {...@props} onFocus={onFocusSpy}/>)
      input      = ReactDOM.findDOMNode view.refs.textInput

      Simulate.focus input

      expect(onFocusSpy).toHaveBeenCalled()


  describe '::onBlur', ->

    it 'should set call passed onBlur handler', ->

      onBlurSpy = expect.createSpy()
      view      = renderIntoDocument(<View {...@props} onBlur={onBlurSpy} />)
      input     = ReactDOM.findDOMNode view.refs.textInput

      Simulate.blur input

      expect(onBlurSpy).toHaveBeenCalled()


  describe '::onKeyDown', ->

    it 'should call passed onKeyDown handler', ->

      onKeyDownSpy = expect.createSpy()
      view         = renderIntoDocument(<View {...@props} onKeyDown={onKeyDownSpy}/>)
      input        = ReactDOM.findDOMNode view.refs.textInput

      Simulate.keyDown input, { which: KeyboardKeys.ESC }

      expect(onKeyDownSpy).toHaveBeenCalled()


  describe '::onChange', ->

    it 'should call passed onChange handler', ->

      onChangeSpy = expect.createSpy()
      view        = renderIntoDocument(<View {...@props} onChange={onChangeSpy}/>)
      input       = ReactDOM.findDOMNode view.refs.textInput

      Simulate.change input

      expect(onChangeSpy).toHaveBeenCalled()


  describe '::onClick', ->

    it 'should call passed postComment handler when click the post comment button', ->

      postCommentSpy = expect.createSpy()
      view           = renderIntoDocument(<View {...@props} postComment={postCommentSpy}/>)
      button         = ReactDOM.findDOMNode view.refs.postComment

      Simulate.click button

      expect(postCommentSpy).toHaveBeenCalled()
