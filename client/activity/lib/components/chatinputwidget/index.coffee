kd                   = require 'kd'
_                    = require 'lodash'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
$                    = require 'jquery'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
DropboxContainer     = require 'activity/components/dropbox/dropboxcontainer'
EmojiSelectBox       = require 'activity/components/emojiselectbox'
formatEmojiName      = require 'activity/util/formatEmojiName'
KeyboardKeys         = require 'app/constants/keyboardKeys'
Link                 = require 'app/components/common/link'
helpers              = require './helpers'
focusOnGlobalKeyDown = require 'activity/util/focusOnGlobalKeyDown'

module.exports = class ChatInputWidget extends React.Component

  { TAB, ESC, ENTER, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

  @propTypes =
    onReady     : React.PropTypes.func
    onResize    : React.PropTypes.func
    placeholder : React.PropTypes.string
    onChange    : React.PropTypes.func
    tokens      : React.PropTypes.array


  @defaultProps =
    onReady     : kd.noop
    onResize    : kd.noop
    placeholder : ''
    onChange    : kd.noop
    tokens      : []


  componentDidMount: ->

    textInput = ReactDOM.findDOMNode this.refs.textInput
    focusOnGlobalKeyDown textInput

    window.addEventListener 'resize', @bound 'updateDropboxPositions'

    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.on 'scroll', @bound 'closeDropboxes'


  componentDidUpdate: (prevProps) ->

    @focus()  if prevProps.value isnt @props.value
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


  onEmojiSelectBoxItemConfirmed: (item) ->

    { value, onChange } = @props

    newValue = value + formatEmojiName item
    @onChange newValue


  handleEmojiButtonClick: (event) -> @props.onSelectboxVisible()


  focus: ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    textInput.focus()


  closeDropboxes: ->

    @refs.emojiSelectBox?.close()
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

    { emojiSelectBoxItems, emojiSelectBoxTabs, emojiSelectBoxQuery } = @props
    { emojiSelectBoxVisibility, emojiSelectBoxSelectedItem, emojiSelectBoxTabIndex } = @props

    <EmojiSelectBox
      items           = { emojiSelectBoxItems }
      tabs            = { emojiSelectBoxTabs }
      query           = { emojiSelectBoxQuery }
      visible         = { emojiSelectBoxVisibility }
      selectedItem    = { emojiSelectBoxSelectedItem }
      tabIndex        = { emojiSelectBoxTabIndex }
      onItemConfirmed = { @bound 'onEmojiSelectBoxItemConfirmed' }
      ref             = 'emojiSelectBox'
      stateId         = { @stateId }
    />


  renderDropbox: ->

    <DropboxContainer ref='dropbox' {...@props} />


  render: ->


    <div className={kd.utils.curry "ChatInputWidget", @props.className}>
      { @renderDropbox() }
      { @renderEmojiSelectBox() }
      <AutoSizeTextarea
        ref           = 'textInput'
        placeholder   = @props.placeholder
        value         = { @props.value }
        onChange      = { @bound 'onChange' }
        onKeyDown     = { @bound 'onKeyDown' }
        onResize      = { @bound 'onResize' }
      />
      <Link
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiButtonClick' }
      />
    </div>
