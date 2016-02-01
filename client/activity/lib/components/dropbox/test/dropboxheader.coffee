kd        = require 'kd'
React     = require 'kd-react'
ReactDOM  = require 'react-dom'
expect    = require 'expect'
TestUtils = require 'react-addons-test-utils'
Header    = require 'activity/components/dropbox/dropboxheader'

describe 'Dropbox.Header', ->

  describe '::render', ->

    it 'renders nothing if title is empty', ->

      result = TestUtils.renderIntoDocument(
        <Header />
      )

      expect(-> TestUtils.findRenderedDOMComponentWithClass result, 'Dropbox-header').toThrow()

    it 'renders title', ->

      result = TestUtils.renderIntoDocument(
        <Header title='Hello' />
      )

      element = TestUtils.findRenderedDOMComponentWithClass result, 'Dropbox-header'
      expect(element.textContent).toEqual 'Hello'

    it 'renders subtitle', ->

      result = TestUtils.renderIntoDocument(
        <Header title='Hello' subtitle='there' />
      )

      element = TestUtils.findRenderedDOMComponentWithClass result, 'Dropbox-subtitle'
      expect(element.textContent).toEqual 'there'
