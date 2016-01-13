kd             = require 'kd'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
expect         = require 'expect'
TestUtils      = require 'react-addons-test-utils'
toImmutable    = require 'app/util/toImmutable'
ChannelDropbox = require '../channeldropbox'
PortalDropbox  = require 'activity/components/dropbox/portaldropbox'

describe 'ChannelDropbox', ->

  channels = toImmutable [
    { id : 1, name : 'qwerty' }
    { id : 2, name : 'test' }
  ]

  describe '::render', ->

    it 'renders invisible dropbox if items are empty', ->

      dropbox = helper.renderDropbox {}
      expect(dropbox.props.visible).toBe no

    it 'renders dropbox with passed items and selected index', ->

      props   = { items : channels, selectedIndex : 1 }
      dropbox = helper.renderDropbox props
      content = dropbox.getContentElement()
      items   = content.querySelectorAll '.DropboxItem'

      expect(items.length).toEqual props.items.size
      for item, i in items
        expect(item.textContent).toEqual "# #{props.items.getIn [i, 'name']}"

      expect(items[props.selectedIndex].classList.contains 'DropboxItem-selected').toBe yes


  describe '::onItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      props = { items : channels, selectedIndex : 0, onItemSelected : kd.noop }
      spy   = expect.spyOn props, 'onItemSelected'

      dropbox = helper.renderDropbox props
      content = dropbox.getContentElement()
      items   = content.querySelectorAll '.DropboxItem'

      newSelectedItem = items[props.selectedIndex + 1]
      TestUtils.Simulate.mouseEnter newSelectedItem

      expect(spy).toHaveBeenCalled()
      expect(spy).toHaveBeenCalledWith props.selectedIndex + 1


  describe '::onItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      props = { items : channels, selectedIndex : 1, onItemConfirmed : kd.noop }
      spy   = expect.spyOn props, 'onItemConfirmed'

      dropbox = helper.renderDropbox props
      content = dropbox.getContentElement()
      items   = content.querySelectorAll '.DropboxItem'

      selectedItem = items[props.selectedIndex]
      TestUtils.Simulate.click selectedItem

      expect(spy).toHaveBeenCalled()


  helper =

    renderDropbox: (props) ->

      result = TestUtils.renderIntoDocument(
        <ChannelDropbox {...props} />
      )
      dropbox = TestUtils.findRenderedComponentWithType result, PortalDropbox
      return dropbox
