kd                   = require 'kd'
_                    = require 'lodash'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
$                    = require 'jquery'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
DropboxContainer     = require 'activity/components/dropbox/dropboxcontainer'
EmojiSelectBox       = require 'activity/components/emojiselectbox'
KeyboardKeys         = require 'app/constants/keyboardKeys'
Link                 = require 'app/components/common/link'
helpers              = require './helpers'
focusOnGlobalKeyDown = require 'activity/util/focusOnGlobalKeyDown'

module.exports = class ChatInputWidget extends React.Component

  { TAB, ESC, ENTER, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

  @propTypes =
    onResize                  : React.PropTypes.func
    placeholder               : React.PropTypes.string
    onChange                  : React.PropTypes.func
    onEnter                   : React.PropTypes.func
    onEsc                     : React.PropTypes.func
    onRightArrow              : React.PropTypes.func
    onDownArrow               : React.PropTypes.func
    onTab                     : React.PropTypes.func
    onLeftArrow               : React.PropTypes.func
    onUpArrow                 : React.PropTypes.func
    onDropboxItemSelected     : React.PropTypes.func
    onDropboxItemConfirmed    : React.PropTypes.func
    onDropboxClose            : React.PropTypes.func
    onSelectBoxVisible        : React.PropTypes.func
    onSelectBoxItemSelected   : React.PropTypes.func
    onSelectBoxItemUnselected : React.PropTypes.func
    onSelectBoxItemConfirmed  : React.PropTypes.func
    onSelectBoxTabChange      : React.PropTypes.func
    onSelectBoxClose          : React.PropTypes.func
    onSelectBoxSearch         : React.PropTypes.func


  @defaultProps =
    onResize                  : kd.noop
    placeholder               : ''
    onChange                  : kd.noop
    onEnter                   : kd.noop
    onEsc                     : kd.noop
    onRightArrow              : kd.noop
    onDownArrow               : kd.noop
    onTab                     : kd.noop
    onLeftArrow               : kd.noop
    onUpArrow                 : kd.noop
    onDropboxItemSelected     : kd.noop
    onDropboxItemConfirmed    : kd.noop
    onDropboxClose            : kd.noop
    onSelectBoxVisible        : kd.noop
    onSelectBoxItemSelected   : kd.noop
    onSelectBoxItemUnselected : kd.noop
    onSelectBoxItemConfirmed  : kd.noop
    onSelectBoxTabChange      : kd.noop
    onSelectBoxClose          : kd.noop
    onSelectBoxSearch         : kd.noop


  componentDidMount: ->

    textInput = ReactDOM.findDOMNode this.refs.textInput
    focusOnGlobalKeyDown textInput

    window.addEventListener 'resize', @bound 'updateDropboxPositions'

    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.on 'scroll', @bound 'closeDropboxes'


  componentDidUpdate: (prevProps) ->

    @focus()  if prevProps.data.value isnt @props.data.value
    @updateDropboxPositions()


  componentWillUnmount: ->

    window.removeEventListener 'resize', @bound 'updateDropboxPositions'

    textInput = ReactDOM.findDOMNode this.refs.textInput
    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.off 'scroll', @bound 'closeDropboxes'


  updateDropboxPositions: ->

    textInput = $ ReactDOM.findDOMNode @refs.textInput

    offset = textInput.offset()
    width  = textInput.outerWidth()
    height = textInput.outerHeight()

    inputDimensions = { width, height, left : offset.left, top : offset.top }
    @refs.dropbox.updatePosition inputDimensions
    @refs.emojiSelectBox.updatePosition inputDimensions


  onChange: (event) ->

    { value } = event.target

    @props.onChange value
    @props.onResize()


  onKeyDown: (event) ->

    { onEnter, onEsc, onRightArrow, onDownArrow, onTab, onLeftArrow, onUpArrow } = @props

    switch event.which
      when ENTER       then onEnter event
      when ESC         then onEsc? event
      when RIGHT_ARROW then onRightArrow event
      when DOWN_ARROW  then onDownArrow event
      when TAB         then onTab event
      when LEFT_ARROW  then onLeftArrow event
      when UP_ARROW    then onUpArrow event


  handleEmojiButtonClick: (event) -> @props.onSelectBoxVisible()


  focus: ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    textInput.focus()


  closeDropboxes: ->

    @props.onSelectBoxClose()
    @props.onDropboxClose()


  isLastItemBeingEdited: ->

    chatItems = document.querySelectorAll '.ChatItem'

    return no  unless chatItems.length

    lastItem = chatItems[chatItems.length - 1]

    return lastItem.firstChild.className.indexOf('editing') > -1


  onResize: ->

    ChatPaneBody    = document.querySelector '.Pane-body'
    scrollContainer = ChatPaneBody.querySelector '.Scrollable'

    { scrollTop, scrollHeight } = scrollContainer

    if @isLastItemBeingEdited()
      scrollContainer.scrollTop = scrollContainer.scrollHeight

    @props.onResize()


  getCursorPosition: ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    helpers.getCursorPosition textInput


  setCursorPosition: (position) ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    helpers.setCursorPosition textInput, position


  renderEmojiSelectBox: ->

    { onSelectBoxItemSelected, onSelectBoxItemUnselected, onSelectBoxItemConfirmed,
      onSelectBoxTabChange, onSelectBoxClose, onSelectBoxSearch, data } = @props
    { emojiSelectBoxItems, emojiSelectBoxTabs, emojiSelectBoxQuery,
      emojiSelectBoxVisibility, emojiSelectBoxSelectedItem, emojiSelectBoxTabIndex } = data

    <EmojiSelectBox
      ref              = 'emojiSelectBox'
      items            = { emojiSelectBoxItems }
      tabs             = { emojiSelectBoxTabs }
      query            = { emojiSelectBoxQuery }
      visible          = { emojiSelectBoxVisibility }
      selectedItem     = { emojiSelectBoxSelectedItem }
      tabIndex         = { emojiSelectBoxTabIndex }
      onItemSelected   = { onSelectBoxItemSelected }
      onItemUnselected = { onSelectBoxItemUnselected }
      onItemConfirmed  = { onSelectBoxItemConfirmed }
      onTabChange      = { onSelectBoxTabChange }
      onClose          = { onSelectBoxClose }
      onSearch         = { onSelectBoxSearch }
    />


  renderDropbox: ->

    { data, onDropboxItemSelected, onDropboxItemConfirmed, onDropboxClose } = @props

    <DropboxContainer {...data}
      ref             = 'dropbox'
      onItemSelected  = { onDropboxItemSelected }
      onItemConfirmed = { onDropboxItemConfirmed }
      onClose         = { onDropboxClose }
    />


  render: ->


    <div className={kd.utils.curry "ChatInputWidget", @props.className}>
      { @renderDropbox() }
      { @renderEmojiSelectBox() }
      <AutoSizeTextarea
        ref           = 'textInput'
        placeholder   = { @props.placeholder }
        value         = { @props.data.value }
        onChange      = { @bound 'onChange' }
        onKeyDown     = { @bound 'onKeyDown' }
        onResize      = { @bound 'onResize' }
      />
      <Link
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiButtonClick' }
      />
    </div>
