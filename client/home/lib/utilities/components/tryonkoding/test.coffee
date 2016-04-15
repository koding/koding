kd                 = require 'kd'
React              = require 'kd-react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TryOnKoding        = require './view'
TestUtils          = require 'react-addons-test-utils'


describe.only 'HomeUtilitiesTryOnKoding', ->
  
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
      
      tryOnKoding = renderIntoDocument(<TryOnKoding checked={yes} secondaryClassName='secondary' value={value}/>)
      
      guideButton = findRenderedDOMComponentWithClass tryOnKoding, 'custom-link-view HomeAppView--button'
      
      tryOnKodingButton = findRenderedDOMComponentWithClass tryOnKodingButton, 'custom-link-view TryOnKodingButton fr'
      
      expect(guideButton).toExist()
      expect(TryOnKodingButton).toExist()
      