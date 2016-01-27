kd        = require 'kd'
React     = require 'kd-react'
expect    = require 'expect'
ReactDOM  = require 'react-dom'
Link      = require '../startvideocalllink'
TestUtils = require 'react-addons-test-utils'

describe 'StartVideoCallLink', ->

  { Simulate
    renderIntoDocument
    findRenderedDOMComponentWithClass } = TestUtils


  afterEach -> expect.restoreSpies()


  describe '::render', ->

    it 'should render link with correct props and classNames', ->

      link = renderIntoDocument(<Link onStart={kd.noop}/>)

      expect(link.props.onStart).toBeA 'function'
      expect(findRenderedDOMComponentWithClass link, 'StartVideoCall-link').toExist()
      expect(findRenderedDOMComponentWithClass link, 'StartVideoCall-icon').toExist()

    it 'should render correct text content', ->

      link = renderIntoDocument(<Link onStart={kd.noop}/>)
      node = ReactDOM.findDOMNode(link).querySelector 'span'

      expect(node.textContent).toEqual 'Start a Video Call'


  describe '::onClick', ->

    it 'should call passed onStart handler when click the link', ->

      onStartSpy = expect.createSpy()
      link       = renderIntoDocument(<Link onStart={onStartSpy}/>)
      node       = ReactDOM.findDOMNode link

      Simulate.click node

      expect(onStartSpy).toHaveBeenCalled()

