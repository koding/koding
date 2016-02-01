kd        = require 'kd'
React     = require 'kd-react'
ReactDOM  = require 'react-dom'
expect    = require 'expect'
TestUtils = require 'react-addons-test-utils'
Dropbox   = require 'activity/components/dropbox/dropboxbody'
Header    = require 'activity/components/dropbox/dropboxheader'

describe 'Dropbox.Body', ->

  describe '::render', ->

    it 'renders dropbox with classes passed in props', ->

      result = TestUtils.renderIntoDocument(
        <Dropbox className='ChannelDropbox' contentClassName='ChannelDropbox-content' />
      )

      container = TestUtils.findRenderedDOMComponentWithClass result, 'Dropbox'
      expect(container.className).toInclude 'ChannelDropbox'

      content = container.querySelector '.ChannelDropbox-content'
      expect(content).toExist()

    it 'renders dropup/dropdown depending on passed type', ->

      result = TestUtils.renderIntoDocument(
        <Dropbox type='dropup' />
      )
      container = TestUtils.findRenderedDOMComponentWithClass result, 'Dropbox'
      expect(container.className).toInclude 'Dropup'

      result = TestUtils.renderIntoDocument(
        <Dropbox type='dropdown' />
      )
      container = TestUtils.findRenderedDOMComponentWithClass result, 'Dropbox'
      expect(container.className).toInclude 'Dropdown'

    it 'renders header', ->

      result = TestUtils.renderIntoDocument(
        <Dropbox title='Emojis matching' subtitle='smile' />
      )

      header = TestUtils.findRenderedComponentWithType result, Header

      expect(header).toExist()
      expect(header.props.title).toEqual 'Emojis matching'
      expect(header.props.subtitle).toEqual 'smile'
