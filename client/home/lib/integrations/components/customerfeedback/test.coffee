kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
CustomerFeedBack   = require './view'
TestUtils          = require 'react-addons-test-utils'


describe 'HomeUtilitiesCustomerFeedBack', ->

  { renderIntoDocument,
  findRenderedDOMComponentWithClass } = TestUtils

  describe '::render', ->

    it 'should render with correct class names', ->

      customerFeedBack = renderIntoDocument(<CustomerFeedBack />)

      separator = findRenderedDOMComponentWithClass customerFeedBack, 'separator'
      warning = findRenderedDOMComponentWithClass customerFeedBack, 'warning'

      expect(separator).toExist()
      expect(warning).toExist()


    it 'should render correct save button and input area', ->

      customerFeedBack = renderIntoDocument(<CustomerFeedBack />)

      saveButton = findRenderedDOMComponentWithClass customerFeedBack, 'custom-link-view HomeAppView--button primary fr'
      expect(saveButton.innerText).toEqual 'SAVE'

      inputArea = findRenderedDOMComponentWithClass customerFeedBack, 'kdinput text'
      expect(inputArea).toExist()
