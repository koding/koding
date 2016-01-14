React     = require 'kd-react'
expect    = require 'expect'
ModalView = require '../view'
TestUtils = require 'react-addons-test-utils'

describe 'BrowsePublicChannelsModalView', ->

  { renderIntoDocument } = TestUtils


  describe '::render', ->

    it 'checks rendered modal props type', ->

      modal = renderIntoDocument(<ModalView isOpen={no}/>)

      expect(modal.props.query).toBeA 'string'
      expect(modal.props.className).toBeA 'string'
      expect(modal.props.onClose).toBeA 'function'
      expect(modal.props.onTabChange).toBeA 'function'
      expect(modal.props.onItemClick).toBeA 'function'
      expect(modal.props.onThresholdReached).toBeA 'function'
      expect(modal.props.onSearchInputChange).toBeA 'function'
      expect(modal.props.isOpen).toBeA 'boolean'
      expect(modal.props.isSearchActive).toBeA 'boolean'

