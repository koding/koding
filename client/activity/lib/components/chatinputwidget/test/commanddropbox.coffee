kd             = require 'kd'
React          = require 'kd-react'
expect         = require 'expect'
toImmutable    = require 'app/util/toImmutable'
CommandDropbox = require '../commanddropbox'
helpers        = require './helpers'

describe 'CommandDropbox', ->

  commands = toImmutable [
    {
      name        : '/search'
      description : 'Search in this channel'
      extraInfo   : '(or /s) anything'
    }
    {
      name        : '/invite'
      description : 'Invite another member to this channel'
      extraInfo   : '@user'
    }
    {
      name        : '/leave'
      description : 'Leave this channel'
    }
  ]


  afterEach -> helpers.clearDropboxes()


  describe '::render', ->

    it 'renders invisible dropbox if query is empty', ->

      dropbox = helpers.renderDropbox {}, CommandDropbox
      expect(dropbox.props.visible).toBe no

    it 'renders error if query is not empty but items are empty', ->

      dropbox = helpers.renderDropbox { query: '/12345' }, CommandDropbox
      expect(dropbox.props.visible).toBe yes

      content = dropbox.getContentElement()
      error   = content.querySelector '.ErrorDropboxItem'
      expect(error).toExist()

    it 'renders dropbox with list of passed items', ->

      props = { query: '/', items : commands }
      helpers.dropboxItemsTest(
        props,
        CommandDropbox,
        (item, itemData) ->
          name = item.querySelector '.CommandDropboxItem-name'
          expect(name).toExist()
          expect(name.textContent).toEqual itemData.get 'name'

          description = item.querySelector '.CommandDropboxItem-description'
          expect(description).toExist()
          expect(description.textContent).toEqual itemData.get 'description'

          return  unless itemData.get 'extraInfo'

          params = item.querySelector '.CommandDropboxItem-params'
          expect(params).toExist()
          expect(params.textContent).toEqual itemData.get 'extraInfo'
      )

    it 'renders dropbox with selected item', ->

      props = { query : '/', items : commands, selectedIndex : 2 }
      helpers.dropboxSelectedItemTest props, CommandDropbox

    it 'renders dropbox with passed query in title', ->

      props = { query : '/search', items : commands.take 1 }

      dropbox = helpers.renderDropbox props, CommandDropbox
      content = dropbox.getContentElement()
      title   = content.parentNode.querySelector '.Dropbox-subtitle'

      expect(title.textContent).toEqual props.query

  describe '::onItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      props = { query : '/', items : commands, selectedIndex : 1 }
      helpers.dropboxSelectedItemCallbackTest props, CommandDropbox


  describe '::onItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      props = { query : '/', items : commands, selectedIndex : 1 }
      helpers.dropboxConfirmedItemCallbackTest props, CommandDropbox
