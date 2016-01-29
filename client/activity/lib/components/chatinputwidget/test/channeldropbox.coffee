kd             = require 'kd'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
expect         = require 'expect'
TestUtils      = require 'react-addons-test-utils'
toImmutable    = require 'app/util/toImmutable'
ChannelDropbox = require '../channeldropbox'
helpers        = require './helpers'
mockingjay     = require '../../../../../mocks/mockingjay'


describe 'ChannelDropbox', ->

  channels = mockingjay.getMockChannels(2).toList()


  afterEach -> helpers.clearDropboxes()


  describe '::render', ->

    it 'renders invisible dropbox if items are empty', ->

      dropbox = helpers.renderDropbox {}, ChannelDropbox
      expect(dropbox.props.visible).toBe no

    it 'renders dropbox with list of passed items', ->

      props = { items : channels }
      helpers.dropboxItemsTest(
        props,
        ChannelDropbox,
        (item, itemData) ->
          expect(item.textContent).toEqual "# #{itemData.get 'name'}"
      )

    it 'renders dropbox with selected item', ->

      props = { items : channels, selectedIndex : 1 }
      helpers.dropboxSelectedItemTest props, ChannelDropbox


  describe '::onItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      props = { items : channels, selectedIndex : 0 }
      helpers.dropboxSelectedItemCallbackTest props, ChannelDropbox


  describe '::onItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      props = { items : channels, selectedIndex : 1 }
      helpers.dropboxConfirmedItemCallbackTest props, ChannelDropbox
