$                 = require 'jquery'
kd                = require 'kd'
React             = require 'kd-react'
classnames        = require 'classnames'
emojify           = require 'emojify.js'
formatEmojiName   = require 'activity/util/formatEmojiName'
ActivityFlux      = require 'activity/flux'
EmojiSelectorItem = require 'activity/components/emojiselectoritem'

module.exports = class EmojiSelector extends React.Component

  DEFAULT_ITEMS_PER_ROW = 8
  ESC = 27

  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'
    document.addEventListener 'keydown',   @bound 'handleKeyDown'

    element = React.findDOMNode this.refs.emojiList
    emojify.run element


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'
    document.removeEventListener 'keydown',   @bound 'handleKeyDown'


  componentDidUpdate: (prevProps, prevState) ->

    element = React.findDOMNode this.refs.selectedEmoji
    emojify.run element


  handleItemSelected: (index) ->

    ActivityFlux.actions.emoji.setCommonListSelectedIndex index


  handleItemClicked: ->

    @props.onItemConfirmed?()


  handleMouseClick: (event) ->

    return  unless @props.visible

    { target } = event
    element    = React.findDOMNode this
    innerClick = $.contains element, target

    ActivityFlux.actions.emoji.resetCommonListFlags()  unless innerClick


  handleKeyDown: (event) ->

    return  unless @props.visible and event.which is ESC

    kd.utils.stopDOMEvent event
    ActivityFlux.actions.emoji.resetCommonListFlags()


  renderList: ->

    { emojis, itemsPerRow, selectedEmoji } = @props
    itemsPerRow ?= DEFAULT_ITEMS_PER_ROW

    emojis.map (emoji, index) =>
      isFirstInRow = (index + 1) % itemsPerRow is 1
      isSelected   = selectedEmoji is emoji

      <EmojiSelectorItem
        emoji        = { emoji }
        index        = { index }
        isFirstInRow = { isFirstInRow }
        isSelected   = { isSelected }
        onSelect     = { kd.utils.throttle 300, @bound 'handleItemSelected' }
        onClick      = { @bound 'handleItemClicked' }
        key          = { emoji }
      />


  render: ->

    { visible, selectedEmoji } = @props

    className = classnames
      'EmojiSelector-container' : yes
      'hidden'                  : not visible

    <div className={className}>
      <div className="EmojiSelector">
        <div className="EmojiSelector-emojiList" ref="emojiList">
          {@renderList()}
        </div>
        <div className="EmojiSelector-footer">
          <div className="EmojiSelector-selectedEmojiIcon" ref="selectedEmoji">
            {formatEmojiName selectedEmoji}
          </div>
          <div className="EmojiSelector-selectedEmojiName">
            {formatEmojiName selectedEmoji}
          </div>
          <div className="clearfix" />
        </div>
      </div>
    </div>
