kd                  = require 'kd'
React               = require 'app/react'
ReactDOM            = require 'react-dom'
expect              = require 'expect'
IntercomIntegration = require './view'
TestUtils           = require 'react-addons-test-utils'


describe 'HomeUtilitiesIntercomIntegration', ->

  { renderIntoDocument,
  findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should render with correct class names', ->

      intercomIntegration = renderIntoDocument(<IntercomIntegration />)

      separator = findRenderedDOMComponentWithClass intercomIntegration, 'separator'
      warning = findRenderedDOMComponentWithClass intercomIntegration, 'warning'

      expect(separator).toExist()
      expect(warning).toExist()


    it 'should render save button and value input', ->

      intercomIntegration = renderIntoDocument(<IntercomIntegration defaultValue='12345' />)

      saveButton = findRenderedDOMComponentWithClass intercomIntegration, 'custom-link-view HomeAppView--button primary fr'
      expect(saveButton.innerText).toEqual 'SAVE'

      input = findRenderedDOMComponentWithClass intercomIntegration, 'kdinput text'
      expect(input).toExist()
      expect(input.value).toBe '12345'


  describe '::onSave', ->

    it 'should call onSave callback once save button is clicked', ->

      spy = expect.createSpy()

      intercomIntegration = renderIntoDocument(<IntercomIntegration defaultValue='12345' onSave={spy} />)

      saveButton = findRenderedDOMComponentWithClass intercomIntegration, 'custom-link-view HomeAppView--button primary fr'
      TestUtils.Simulate.click saveButton

      expect(spy).toHaveBeenCalled()
