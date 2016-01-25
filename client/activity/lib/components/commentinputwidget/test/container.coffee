kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
expect       = require 'expect'
Container    = require '../container'
TestUtils    = require 'react-addons-test-utils'
ActivityFlux = require 'activity/flux'
immutable    = require 'immutable'
toImmutable  = require 'app/util/toImmutable'
mock         = require '../../../../../mocks/mockingjay'
KeyboardKeys = require 'app/constants/keyboardKeys'


describe 'CommentInputWidgetContainer', ->

  { renderIntoDocument, isCompositeComponent } = TestUtils

  beforeEach ->

    @props =
      hasValue     : yes
      cancelEdit   : kd.noop
      postComment  : kd.noop
      onChange     : kd.noop
      commentValue : 'dummy-comment-value'


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'renders container with correct props and state', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.props.hasValue).toBeTruthy()
      expect(container.props.onChange).toBeA 'function'
      expect(container.props.cancelEdit).toBeA 'function'
      expect(container.props.postComment).toBeA 'function'
      expect(container.props.commentValue).toEqual 'dummy-comment-value'
      expect(isCompositeComponent container.refs.view).toBeTruthy()
      expect(container.state.focusOnInput).toBeFalsy()


  describe '::onFocus', ->

    it 'should set focusOnInput state as yes', ->

      container = renderIntoDocument(<Container {...@props} />)

      expect(container.state.focusOnInput).toBeFalsy()

      container.onFocus()

      expect(container.state.focusOnInput).toBeTruthy()


  describe '::onBlur', ->

    it 'should set focusOnInput state as no', ->

      container = renderIntoDocument(<Container {...@props} />)

      container.setState { focusOnInput: yes }

      expect(container.state.focusOnInput).toBeTruthy()

      container.onBlur()

      expect(container.state.focusOnInput).toBeFalsy()


  describe '::onKeyDown', ->

    it 'should call passed cancelEdit handler when key down to ESC', ->

      cancelEditSpy = expect.createSpy()
      container = renderIntoDocument(<Container {...@props} cancelEdit={cancelEditSpy}/>)

      container.onKeyDown { which: KeyboardKeys.ESC }

      expect(cancelEditSpy).toHaveBeenCalled()


