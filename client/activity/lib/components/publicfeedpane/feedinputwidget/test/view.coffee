kd        = require 'kd'
View      = require '../view'
React     = require 'kd-react'
expect    = require 'expect'
ReactDOM  = require 'react-dom'
TestUtils = require 'react-addons-test-utils'


describe 'FeedInputWidgetView', ->

  { Simulate
   createRenderer
   renderIntoDocument
   findRenderedDOMComponentWithClass } = TestUtils

  beforeEach ->
    @props =
      value       : ''
      onClick     : kd.noop
      onSubmit    : kd.noop
      onChange    : kd.noop
      onKeyDown   : kd.noop
      previewMode : no

  describe '::render', ->

    it 'should render view with correct classname', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<View  />)

      view = shallowRenderer.getRenderOutput()

      expect(view.type).toEqual 'div'
      expect(view.props.className).toEqual 'FeedInputWidget'


    it 'should render children with correct classname', ->

      view = renderIntoDocument(<View />)

      buttonBarDiv  = findRenderedDOMComponentWithClass view, 'FeedInputWidget-buttonBar'
      buttonBarBtn  = findRenderedDOMComponentWithClass view, 'FeedInputWidget-preview'
      buttonBarSend = findRenderedDOMComponentWithClass view, 'FeedInputWidget-send'

      expect(buttonBarDiv).toExist()
      expect(buttonBarBtn).toExist()
      expect(buttonBarSend).toExist()
      expect(view.refs.Preview).toExist()


  describe '::onChance', ->

    it 'should create action when onChange triggered', ->

      spy  = expect.createSpy()
      view = renderIntoDocument(<View onChange={ spy } />)

      inputWidget = ReactDOM.findDOMNode view.refs.InputWidget

      Simulate.change inputWidget

      expect(spy).toHaveBeenCalled()


  describe '::onKeyDown', ->

    it 'should create action when onKeyDown triggered', ->

      spy  = expect.createSpy()
      view = renderIntoDocument(<View onKeyDown={ spy } />)

      inputWidget = ReactDOM.findDOMNode view.refs.InputWidget

      Simulate.keyDown inputWidget

      expect(spy).toHaveBeenCalled()



  describe '::onClick', ->

    it 'should create action when preview button clicked', ->

      spy  = expect.createSpy()

      view = renderIntoDocument(<View toggleMarkdownPreviewMode={ spy } />)

      button = findRenderedDOMComponentWithClass view, 'FeedInputWidget-preview'

      Simulate.click button

      expect(spy).toHaveBeenCalled()


    it 'should create action when send button clicked', ->

      spy  = expect.createSpy()

      view = renderIntoDocument(<View onSubmit={ spy } />)

      button = findRenderedDOMComponentWithClass view, 'FeedInputWidget-send'

      Simulate.click button

      expect(spy).toHaveBeenCalled()