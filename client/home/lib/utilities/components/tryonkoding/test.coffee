kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TryOnKoding        = require './view'
TestUtils          = require 'react-addons-test-utils'


describe 'HomeUtilitiesTryOnKoding', ->

  { createRenderer,
  renderIntoDocument,
  findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should render with correct components', ->

      tryOnKoding = renderIntoDocument(<TryOnKoding
        checked={no} primaryClassName='primary' secondaryClassName='secondary hidden'/>)

      primary = findRenderedDOMComponentWithClass tryOnKoding, 'primary'
      expect(primary).toExist()

      codeBlock = findRenderedDOMComponentWithClass tryOnKoding, 'HomeAppView--code block'
      expect(codeBlock).toExist()

    it 'should render correct code block', ->

      value = 'CodeBlock'
      tryOnKoding = renderIntoDocument(<TryOnKoding checked={yes} secondaryClassName='secondary' value={value}/>)

      codeBlock = tryOnKoding.refs.textarea.value

      expect(codeBlock).toEqual value

    it 'should render buttons', ->

      tryOnKoding = renderIntoDocument(<TryOnKoding checked={yes} secondaryClassName='secondary'/>)

      guideButton = findRenderedDOMComponentWithClass tryOnKoding, 'custom-link-view HomeAppView--button'

      tryOnKodingButton = findRenderedDOMComponentWithClass tryOnKoding, 'TryOnKodingButton'

      expect(guideButton).toExist()
      expect(tryOnKodingButton).toExist()
