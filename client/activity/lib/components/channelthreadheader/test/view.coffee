kd          = require 'kd'
expect      = require 'expect'
View        = require '../view'
React       = require 'kd-react'
ReactDOM    = require 'react-dom'
TestUtils   = require 'react-addons-test-utils'
toImmutable = require 'app/util/toImmutable'
mock        = require '../../../../../mocks/mockingjay'


{
  Simulate
  renderIntoDocument
  findRenderedDOMComponentWithClass } = TestUtils


describe 'ChannelThreadHeaderView', ->


  beforeEach ->

    channelId = 'koding-dummy-channel'

    @props =
      thread       : toImmutable mock.getMockThread({ channelId })
      onKeyDown    : kd.noop
      onClose      : kd.noop
      onChange     : kd.noop
      onVideoStart : kd.noop


  afterEach -> expect.restoreSpies()


  describe '::render', ->


    it 'should render view with correct props', ->

      view = renderIntoDocument(<View {...@props} />)

      expect(view.props.editingPurpose).toBeFalsy()
      expect(view.props.isModalOpen).toBeFalsy()
      expect(view.refs.purposeInput).toExist()
      expect(view.props.onClose).toBeA 'function'
      expect(view.props.onKeyDown).toBeA 'function'
      expect(view.props.onVideoStart).toBeA 'function'
      expect(view.props.onChange).toBeA 'function'


    it 'should render view and its children with correct classNames', ->

      view = renderIntoDocument(<View {...@props} className='dummy-class' editingPurpose={yes}/>)

      expect(findRenderedDOMComponentWithClass view, 'editing').toExist()
      expect(findRenderedDOMComponentWithClass view, 'dummy-class').toExist()
      expect(findRenderedDOMComponentWithClass view, 'ThreadHeader').toExist()
      expect(findRenderedDOMComponentWithClass view, 'ChannelThreadPane-purpose').toExist()
      expect(findRenderedDOMComponentWithClass view, 'ChannelThreadPane-purposeWrapper').toExist()


    it 'should render correct purpose text', ->

      purpose = @props.thread.getIn ['channel', 'purpose']
      view    = renderIntoDocument(<View {...@props} />)
      node    = findRenderedDOMComponentWithClass view, 'ChannelThreadPane-purpose'

      expect(node.textContent).toEqual purpose


  describe '::onKeyDown', ->

    it 'should call passed handler on purpose input keydown', ->

      onKeyDownSpy = expect.createSpy()
      view         = renderIntoDocument(<View {...@props} onKeyDown={onKeyDownSpy}/>)
      input        = ReactDOM.findDOMNode(view.refs.purposeInput)

      Simulate.keyDown input

      expect(onKeyDownSpy).toHaveBeenCalled()


  describe '::onChange', ->

    it 'should call passed handler on purpose input change', ->

      onChangeSpy = expect.createSpy()
      view        = renderIntoDocument(<View {...@props} onChange={onChangeSpy}/>)
      input       = ReactDOM.findDOMNode(view.refs.purposeInput)

      Simulate.change input

      expect(onChangeSpy).toHaveBeenCalled()

