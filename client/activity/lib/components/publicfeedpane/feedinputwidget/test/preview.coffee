kd        = require 'kd'
Link      = require 'app/components/common/link'
React     = require 'kd-react'
expect    = require 'expect'
Preview   = require '../preview'
ReactDOM  = require 'react-dom'
TestUtils = require 'react-addons-test-utils'


describe 'FeedInputWidgetPreview', ->

  { Simulate
   createRenderer
   renderIntoDocument
   findRenderedDOMComponentWithClass
   findRenderedDOMComponentWithTag
   scryRenderedDOMComponentsWithTag } = TestUtils

  beforeEach ->
    @props =
      value                     : ''
      previewMode               : no
      toggleMarkdownPreviewMode : kd.noop


  describe '::render', ->

    it 'should render preview with correct class name', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<Preview previewMode = { yes } />)

      preview = shallowRenderer.getRenderOutput()

      expect(preview.type).toEqual 'div'
      expect(preview.props.className).toEqual 'FeedInputWidget-previewWrapper MediaObject'


    it 'should render children with correct class name', ->

      preview = renderIntoDocument(<Preview {...@props} previewMode = { yes } />)

      mediaDiv = findRenderedDOMComponentWithClass preview, 'MediaObject-media'
      dateDiv  = findRenderedDOMComponentWithClass preview, 'FeedInputWidget-previewDate'
      bodyDiv  = findRenderedDOMComponentWithClass preview, 'FeedInputWidget-previewBody'
      link     = findRenderedDOMComponentWithClass preview, 'FeedInputWidget-closePreview'

      expect(mediaDiv).toExist()
      expect(dateDiv).toExist()
      expect(bodyDiv).toExist()
      expect(link).toExist()


  describe '::onClick', ->

    it 'should create action', ->

      spy = expect.createSpy()

      preview = renderIntoDocument(<Preview {...@props} toggleMarkdownPreviewMode={ spy } previewMode = { yes } />)

      link = findRenderedDOMComponentWithClass preview, 'FeedInputWidget-closePreview'

      Simulate.click link

      expect(spy).toHaveBeenCalled()