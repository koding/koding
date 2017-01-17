kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
KDCli              = require './view'
TestUtils          = require 'react-addons-test-utils'


describe 'HomeUtilitiesKD', ->

  { createRenderer,
  renderIntoDocument,
  findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should render with correct key, code block and button', ->

      copyKey = 'key'
      cmd = 'export KONTROLURL'
      kdcli = renderIntoDocument(<KDCli copyKey={copyKey} cmd={cmd}/>)

      codeBlock = findRenderedDOMComponentWithClass kdcli, 'HomeAppView--code block'

      span = codeBlock.childNodes[0].innerHTML
      cite = codeBlock.childNodes[1].innerHTML

      expect(span).toEqual cmd
      expect(cite).toEqual copyKey

      guideButton = findRenderedDOMComponentWithClass kdcli,'HomeAppView--button primary'

      expect(guideButton.innerHTML).toEqual 'VIEW GUIDE'
