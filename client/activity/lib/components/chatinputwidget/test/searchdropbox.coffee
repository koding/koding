kd            = require 'kd'
React         = require 'kd-react'
ReactDOM      = require 'react-dom'
expect        = require 'expect'
TestUtils     = require 'react-addons-test-utils'
toImmutable   = require 'app/util/toImmutable'
SearchDropbox = require '../searchdropbox'
helpers       = require './helpers'
mockingjay    = require '../../../../../mocks/mockingjay'

describe 'SearchDropbox', ->

  items = toImmutable [
    { message : mockingjay.getMockMessage 'Life on Mars' }
    { message : mockingjay.getMockMessage 'Expedition on Mars' }
  ]


  afterEach -> helpers.clearDropboxes()


  describe '::render', ->

    it 'renders error if query is not empty but items are empty', ->

      dropbox = helpers.renderDropbox { query: 'test' }, SearchDropbox
      expect(dropbox.props.visible).toBe yes

      content = dropbox.getContentElement()
      error   = content.querySelector '.ErrorDropboxItem'
      expect(error).toExist()

    it 'renders "continue typing" message if query is empty', ->

      dropbox = helpers.renderDropbox {}, SearchDropbox
      expect(dropbox.props.visible).toBe yes

      content = dropbox.getContentElement()
      error   = content.querySelector '.emptyQueryMessage'
      expect(error).toExist()

    it 'renders dropbox with list of passed items', ->

      props = { query: 'mars', items }
      helpers.dropboxItemsTest(
        props,
        SearchDropbox,
        (item, itemData) ->
          body = item.querySelector 'article'
          expect(body).toExist()
          expect(body.textContent).toEqual itemData.getIn [ 'message', 'body' ]
      )

    it 'renders dropbox with selected item', ->

      props = { query : 'mars', items, selectedIndex : 1 }
      helpers.dropboxSelectedItemTest props, SearchDropbox

  describe '::onItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      props = { query : 'mars', items, selectedIndex : 0 }
      helpers.dropboxSelectedItemCallbackTest props, SearchDropbox


  describe '::onItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      props = { query : 'mars', items, selectedIndex : 1 }
      helpers.dropboxConfirmedItemCallbackTest props, SearchDropbox
