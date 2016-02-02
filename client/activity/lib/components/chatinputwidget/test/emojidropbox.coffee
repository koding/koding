kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
expect       = require 'expect'
TestUtils    = require 'react-addons-test-utils'
toImmutable  = require 'app/util/toImmutable'
EmojiDropbox = require '../emojidropbox'
helpers      = require './helpers'

describe 'EmojiDropbox', ->

  query = 'bee'
  emojis = toImmutable [ 'bee', 'beer', 'honeybee' ]


  afterEach -> helpers.clearDropboxes()


  describe '::render', ->

    it 'renders invisible dropbox if items are empty', ->

      dropbox = helpers.renderDropbox {}, EmojiDropbox
      expect(dropbox.props.visible).toBe no

    it 'renders dropbox with list of passed items', ->

      props = { query, items : emojis }
      helpers.dropboxItemsTest(
        props,
        EmojiDropbox,
        (item, itemData) ->
          expect(item.textContent).toEqual ":#{itemData}:"
          if itemData is 'honeybee'
            highlighted = item.querySelector 'strong'
            expect(highlighted).toExist()
            expect(highlighted.innerHTML).toEqual 'bee'
      )

    it 'renders dropbox with selected item', ->

      props = { query, items : emojis, selectedIndex : 1 }
      helpers.dropboxSelectedItemTest props, EmojiDropbox


    it 'renders dropbox with passed query in title', ->

      props = { query, items : emojis }

      dropbox = helpers.renderDropbox props, EmojiDropbox
      content = dropbox.getContentElement()
      title   = content.parentNode.querySelector '.Dropbox-subtitle'

      expect(title.textContent).toEqual ":#{props.query}"


  describe '::onItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      props = { query, items : emojis, selectedIndex : 1 }
      helpers.dropboxSelectedItemCallbackTest props, EmojiDropbox


  describe '::onItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      props = { query, items : emojis, selectedIndex : 2 }
      helpers.dropboxConfirmedItemCallbackTest props, EmojiDropbox
