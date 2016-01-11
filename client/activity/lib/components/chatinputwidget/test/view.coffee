React           = require 'react/addons'
ReactDOM        = require 'react-dom'
expect          = require 'expect'
{ TestUtils }   = React.addons
toImmutable     = require 'app/util/toImmutable'
KeyboardKeys    = require 'app/constants/keyboardKeys'
EmojiDropbox    = require 'activity/components/emojidropbox'
PortalDropbox   = require 'activity/components/dropbox/portaldropbox'
ChatInputWidget = require 'activity/components/chatinputwidget/view'

describe 'ChatInputWidget', ->

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


  it 'calls onChange() callback when input value is changed', ->

    value     = ''
    testValue = 'whoa'
    callback = (newValue) -> value = newValue

    result = TestUtils.renderIntoDocument(
      <ChatInputWidget data={{}} onChange={callback} />
    )

    input = TestUtils.findRenderedDOMComponentWithTag result, 'textarea'
    input.value = testValue
    TestUtils.Simulate.change input

    expect(value).toEqual testValue


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


  it 'calls onDropboxItemSelected() callback when dropbox item is hovered', ->

    newSelectedIndex = data.selectedIndex
    callback = (index) -> newSelectedIndex = index

    result = TestUtils.renderIntoDocument(
      <ChatInputWidget data={data} onDropboxItemSelected={callback} />
    )

    component = TestUtils.findRenderedComponentWithType result, EmojiDropbox
    expect(component).toExist()

    dropbox = TestUtils.findRenderedComponentWithType component, PortalDropbox
    content = dropbox.getContentElement()
    items   = content.querySelectorAll '.DropboxItem'

    newSelectedItem = items[data.selectedIndex + 1]
    TestUtils.Simulate.mouseEnter newSelectedItem
    expect(newSelectedIndex).toEqual data.selectedIndex + 1


  it 'calls onDropboxItemConfirmed() callback when dropbox item is clicked', ->

    flag = no
    callback = -> flag = yes

    result = TestUtils.renderIntoDocument(
      <ChatInputWidget data={data} onDropboxItemConfirmed={callback} />
    )

    component = TestUtils.findRenderedComponentWithType result, EmojiDropbox
    expect(component).toExist()

    dropbox = TestUtils.findRenderedComponentWithType component, PortalDropbox
    content = dropbox.getContentElement()
    items   = content.querySelectorAll '.DropboxItem'

    selectedItem = items[data.selectedIndex]
    TestUtils.Simulate.click selectedItem
    expect(flag).toBe yes


  it 'calls proper callbacks according to pressed input keys', ->

    { TAB, ESC, ENTER, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

    key = null

    onEnter      = -> key = 'enter'
    onEsc        = -> key = 'esc'
    onRightArrow = -> key = 'right'
    onDownArrow  = -> key = 'down'
    onTab        = -> key = 'tab'
    onLeftArrow  = -> key = 'left'
    onUpArrow    = -> key = 'up'

    result = TestUtils.renderIntoDocument(
      <ChatInputWidget
        data         = { {} }
        onEnter      = { onEnter }
        onEsc        = { onEsc }
        onRightArrow = { onRightArrow }
        onDownArrow  = { onDownArrow }
        onTab        = { onTab }
        onLeftArrow  = { onLeftArrow }
        onUpArrow    = { onUpArrow }
      />
    )

    input = TestUtils.findRenderedDOMComponentWithTag result, 'textarea'
    TestUtils.Simulate.keyDown input, { keyCode: ENTER, which: ENTER }
    expect(key).toEqual 'enter'

    TestUtils.Simulate.keyDown input, { keyCode: ESC, which: ESC }
    expect(key).toEqual 'esc'

    TestUtils.Simulate.keyDown input, { keyCode: RIGHT_ARROW, which: RIGHT_ARROW }
    expect(key).toEqual 'right'

    TestUtils.Simulate.keyDown input, { keyCode: DOWN_ARROW, which: DOWN_ARROW }
    expect(key).toEqual 'down'

    TestUtils.Simulate.keyDown input, { keyCode: TAB, which: TAB }
    expect(key).toEqual 'tab'

    TestUtils.Simulate.keyDown input, { keyCode: LEFT_ARROW, which: LEFT_ARROW }
    expect(key).toEqual 'left'

    TestUtils.Simulate.keyDown input, { keyCode: UP_ARROW, which: UP_ARROW }
    expect(key).toEqual 'up'


