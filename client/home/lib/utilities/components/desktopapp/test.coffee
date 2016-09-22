kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
DesktopApp         = require './view'
TestUtils          = require 'react-addons-test-utils'


describe 'HomeUtilitiesDesktopApp', ->

  { createRenderer,
  renderIntoDocument,
  findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should render with correct buttons and content', ->

      desktopapp = renderIntoDocument <DesktopApp />

      linkHolder = findRenderedDOMComponentWithClass desktopapp, 'link-holder'
      downloadButton = linkHolder.childNodes[0]
      guideButton = linkHolder.childNodes[1]

      expect(guideButton.innerText).toEqual 'VIEW GUIDE'
      expect(downloadButton.innerText).toEqual 'DOWNLOAD'
