kd              = require 'kd'
React           = require 'kd-react'
ReactDOM        = require 'react-dom'
expect          = require 'expect'
InputWidgetView = require '../view'
InputWidget     = require '../index'
immutable       = require 'immutable'
TestUtils       = require 'react-addons-test-utils'
keyboardKeys    = require 'app/constants/keyboardKeys'

describe 'ChannelParticipantsInputWidgetView', ->

  { Simulate, renderIntoDocument, isCompositeComponent } = TestUtils
  { ENTER, UP_ARROW, DOWN_ARROW, TAB } = keyboardKeys


  beforeEach ->

    @props =
      onChange              : kd.noop
      onKeyDown             : kd.noop
      query                 : 'koding-dummy-query'
      value                 : 'koding-dummy-query'
      placeholder           : 'koding-dummy-placeholder'
      visible               : yes
      addNewParticipantMode : no
      selectedItem          : null
      selectedIndex         : 1
      items                 : immutable.List()


  afterEach  -> expect.restoreSpies()


  describe '::render', ->

    it 'should render ChannelParticipantsInputWidgetView with correct props', ->

      view = renderIntoDocument(<InputWidgetView {...@props}/>)

      expect(view.props.value).toBeA 'string'
      expect(view.props.query).toBeA 'string'
      expect(view.props.visible).toBeTruthy()
      expect(view.props.items).toBeA(immutable.List)
      expect(view.props.selectedIndex).toEqual 1
      expect(view.props.addNewParticipantMode).toBeFalsy()
      expect(isCompositeComponent(view.refs.dropdown)).toBeTruthy()
      expect(view.props.placeholder).toEqual 'koding-dummy-placeholder'


    it 'should render ChannelParticipantsDropdown DOM node', ->

      view = renderIntoDocument(<InputWidgetView {...@props}/>)
      node = ReactDOM.findDOMNode(view.refs.dropdown)

      expect(node).toExist()


  describe '::onChange', ->

    it 'should call passed handler on input change', ->

      onChangeSpy = expect.createSpy()

      view  = renderIntoDocument(<InputWidgetView {...@props} onChange={onChangeSpy}/>)
      input = ReactDOM.findDOMNode(view.refs.textInput)

      Simulate.change input

      expect(onChangeSpy).toHaveBeenCalled()


  describe '::onKeyDown', ->

    it 'should call passed handler on input key down', ->

      onKeyDownSpy = expect.createSpy()

      view  = renderIntoDocument(<InputWidgetView {...@props} onKeyDown={onKeyDownSpy}/>)
      input = ReactDOM.findDOMNode(view.refs.textInput)

      Simulate.keyDown input

      expect(onKeyDownSpy).toHaveBeenCalled()


    it 'should call onEnter handler when input on enter key down', ->

      container  = renderIntoDocument(<InputWidget.Container {...@props}/>)
      onEnterSpy = expect.spyOn container, 'onEnter'
      input      = ReactDOM.findDOMNode(container.refs.view.refs.textInput)

      Simulate.keyDown input, { key: 'Enter', keyCode: ENTER, which: ENTER }

      expect(onEnterSpy).toHaveBeenCalled()


    it 'should call onPrevPosition handler when input on up-arrow key down', ->

      container         = renderIntoDocument(<InputWidget.Container {...@props}/>)
      onPrevPositionSpy = expect.spyOn container, 'onPrevPosition'
      input             = ReactDOM.findDOMNode(container.refs.view.refs.textInput)

      Simulate.keyDown input, { key: 'upArrow', keyCode: UP_ARROW, which: UP_ARROW }

      expect(onPrevPositionSpy).toHaveBeenCalled()


    it 'should call onNextPosition handler when input on down-arrow key down', ->

      container         = renderIntoDocument(<InputWidget.Container {...@props}/>)
      onNextPositionSpy = expect.spyOn container, 'onNextPosition'
      input             = ReactDOM.findDOMNode(container.refs.view.refs.textInput)

      Simulate.keyDown input, { key: 'downArrow', keyCode: DOWN_ARROW, which: DOWN_ARROW }

      expect(onNextPositionSpy).toHaveBeenCalled()


    it 'should call onNextPosition handler when input on tab key down', ->

      container         = renderIntoDocument(<InputWidget.Container {...@props}/>)
      onNextPositionSpy = expect.spyOn container, 'onNextPosition'
      input             = ReactDOM.findDOMNode(container.refs.view.refs.textInput)

      Simulate.keyDown input, { key: 'tab', keyCode: TAB, which: TAB }

      expect(onNextPositionSpy).toHaveBeenCalled()


