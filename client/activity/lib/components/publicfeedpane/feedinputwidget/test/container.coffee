View         = require './view'
React        = require 'kd-react'
expect       = require 'expect'
ReactDOM     = require 'react-dom'
TestUtils    = require 'react-addons-test-utils'
InputWidget  = require '../container'
KeyboardKeys = require 'app/constants/keyboardKeys'
ActivityFlux = require 'activity/flux'


describe 'FeedInputWidgetContainer', ->

  { renderIntoDocument } = TestUtils

  { message } = ActivityFlux.actions

  beforeEach ->

    @props =
      channelId : 'koding-dummy-query'


  afterEach -> expect.restoreSpies()

  describe '::render', ->

    it 'should render container with correct props', ->

      container = renderIntoDocument(<InputWidget {...@props}/>)

      expect(container.props.channelId).toEqual 'koding-dummy-query'


  describe '::onChange', ->

    it 'should change state value', ->

      event =
        target:
          value: 'koding-dummy-query'

      container = renderIntoDocument(<InputWidget />)
      container.onChange event

      expect(container.state.value).toEqual 'koding-dummy-query'


  describe '::toggleMarkdownPreviewMode', ->

    it 'should invert state preview mode', ->

      event =
        previewMode : no

      container = renderIntoDocument(<InputWidget />)
      container.toggleMarkdownPreviewMode event

      expect(container.state.previewMode).toEqual yes


  describe '::onKeyDown', ->

    it 'should call onSubmit function if event has metakey and keycode is Enter', ->

      event = document.createEvent('Event')
      event.metaKey = true
      event.keyCode = KeyboardKeys.ENTER

      container = renderIntoDocument(<InputWidget {...@props}/>)

      onSubmit = expect.spyOn(container, 'onSubmit').andCallThrough()

      container.setState({ value: ''})

      container.onKeyDown event

      expect(onSubmit).toHaveBeenCalled()


  describe '::onSubmit', ->

    it 'should call action if there is state value', ->

      createMessageSpy = expect.spyOn(message, 'createMessage')

      container = renderIntoDocument(<InputWidget {...@props}/>)

      { props, state } = container

      state.value = 'koding-dummy-query'

      message.createMessage(props.channelId, state.value)

      expect(createMessageSpy).toHaveBeenCalled()

