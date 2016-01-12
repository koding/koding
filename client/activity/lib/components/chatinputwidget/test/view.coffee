kd              = require 'kd'
React           = require 'kd-react'
ReactDOM        = require 'react-dom'
expect          = require 'expect'
TestUtils       = require 'react-addons-test-utils'
toImmutable     = require 'app/util/toImmutable'
KeyboardKeys    = require 'app/constants/keyboardKeys'
EmojiDropbox    = require 'activity/components/emojidropbox'
PortalDropbox   = require 'activity/components/dropbox/portaldropbox'
ChatInputWidget = require 'activity/components/chatinputwidget/view'

describe 'ChatInputWidget.View', ->

  data = {
    dropboxConfig : toImmutable {
      component   : EmojiDropbox
      getters     : {
        'items'
        'selectedIndex'
        'query'
      }
    }
    items         : toImmutable [ 'whale', 'white_check_mark', 'white_circle' ]
    selectedIndex : 1
    query         : 'wh'
  }

  describe '::render', ->

    it 'renders input with provided prop value and placeholder', ->

      value       = '12345'
      placeholder = 'Type here...'
      result = TestUtils.renderIntoDocument(
        <ChatInputWidget placeholder={placeholder} data={{ value }} />
      )

      input = TestUtils.findRenderedDOMComponentWithTag result, 'textarea'

      value = input.value
      expect(value).toEqual value
      expect(input.getAttribute 'placeholder').toEqual placeholder

    it 'renders dropbox according to dropbox config and passed data', ->

      result = TestUtils.renderIntoDocument(
        <ChatInputWidget data={data} />
      )

      component = TestUtils.findRenderedComponentWithType result, EmojiDropbox
      expect(component).toExist()

      dropbox = TestUtils.findRenderedComponentWithType component, PortalDropbox
      content = dropbox.getContentElement()
      title   = content.parentNode.querySelector '.Dropbox-subtitle'
      items   = content.querySelectorAll '.DropboxItem'

      expect(title.textContent).toEqual ":#{data.query}"
      expect(items.length).toEqual data.items.size
      for item, i in items
        expect(item.textContent).toEqual ":#{data.items.get i}:"
      expect(items[data.selectedIndex].classList.contains 'DropboxItem-selected').toBe yes

      result = TestUtils.renderIntoDocument(
        <ChatInputWidget data={{}} />
      )

      expect(-> TestUtils.findRenderedComponentWithType  result, EmojiDropbox).toThrow()


  describe '::onChange', ->

    it 'should be called when input value is changed', ->

      testValue = 'whoa'

      { input, spy } = helper.renderWidgetWithInputCallback 'onChange'

      input.value = testValue
      TestUtils.Simulate.change input

      expect(spy).toHaveBeenCalled()
      expect(spy).toHaveBeenCalledWith testValue


  describe '::onDropboxItemSelected', ->

    it 'should be called when dropbox item is hovered', ->

      { dropbox, spy } = helper.renderWidgetWithDropboxCallback 'onDropboxItemSelected', data, EmojiDropbox

      content = dropbox.getContentElement()
      items   = content.querySelectorAll '.DropboxItem'

      newSelectedItem = items[data.selectedIndex + 1]
      TestUtils.Simulate.mouseEnter newSelectedItem

      expect(spy).toHaveBeenCalled()
      expect(spy).toHaveBeenCalledWith data.selectedIndex + 1


  describe '::onDropboxItemConfirmed', ->

    it 'should be called when dropbox item is clicked', ->

      { dropbox, spy } = helper.renderWidgetWithDropboxCallback 'onDropboxItemConfirmed', data, EmojiDropbox

      content = dropbox.getContentElement()
      items   = content.querySelectorAll '.DropboxItem'

      selectedItem = items[data.selectedIndex]
      TestUtils.Simulate.click selectedItem

      expect(spy).toHaveBeenCalled()


  describe '::onEnter', ->

    it 'should be called when ENTER is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onEnter'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.ENTER }
      expect(spy).toHaveBeenCalled()


  describe '::onEsc', ->

    it 'should be called when ESC is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onEsc'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.ESC }
      expect(spy).toHaveBeenCalled()


  describe '::onRightArrow', ->

    it 'should be called when RIGHT_ARROW is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onRightArrow'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.RIGHT_ARROW }
      expect(spy).toHaveBeenCalled()


  describe '::onDownArrow', ->

    it 'should be called when DOWN_ARROW is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onDownArrow'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.DOWN_ARROW }
      expect(spy).toHaveBeenCalled()


  describe '::onTab', ->

    it 'should be called when TAB is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onTab'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.TAB }
      expect(spy).toHaveBeenCalled()


  describe '::onLeftArrow', ->

    it 'should be called when LEFT_ARROW is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onLeftArrow'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.LEFT_ARROW }
      expect(spy).toHaveBeenCalled()


  describe '::onUpArrow', ->

    it 'should be called when UP_ARROW is pressed', ->

      { input, spy } = helper.renderWidgetWithInputCallback 'onUpArrow'
      TestUtils.Simulate.keyDown input, { which: KeyboardKeys.UP_ARROW }
      expect(spy).toHaveBeenCalled()


  helper =

    renderWidgetWithCallback: (eventName, data = {}) ->

      props = { data }
      props[eventName] = kd.noop

      spy    = expect.spyOn props, eventName
      widget = TestUtils.renderIntoDocument(
        <ChatInputWidget {...props} />
      )

      return { widget, spy }


    renderWidgetWithDropboxCallback: (eventName, data, dropboxType) ->

      { widget, spy } = helper.renderWidgetWithCallback eventName, data

      component = TestUtils.findRenderedComponentWithType widget, dropboxType
      dropbox = TestUtils.findRenderedComponentWithType component, PortalDropbox

      return { dropbox, spy }


    renderWidgetWithInputCallback: (eventName) ->

      { widget, spy } = helper.renderWidgetWithCallback eventName

      input  = TestUtils.findRenderedDOMComponentWithTag widget, 'textarea'

      return { input, spy }
