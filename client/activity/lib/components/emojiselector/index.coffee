$                 = require 'jquery'
kd                = require 'kd'
React             = require 'kd-react'
classnames        = require 'classnames'
immutable         = require 'immutable'
emojify           = require 'emojify.js'
formatEmojiName   = require 'activity/util/formatEmojiName'
ActivityFlux      = require 'activity/flux'
Dropup            = require 'activity/components/dropup'
EmojiSelectorItem = require 'activity/components/emojiselectoritem'

module.exports = class EmojiSelector extends React.Component

  ESC = 27

  @defaultProps =
    items        : immutable.List()
    visible      : no
    itemsPerRow  : 8
    selectedItem : immutable.Map()


  componentDidMount: ->

    document.addEventListener 'keydown',   @bound 'handleKeyDown'

    element = React.findDOMNode this.refs.list
    emojify.run element


  componentWillUnmount: ->

    document.removeEventListener 'keydown',   @bound 'handleKeyDown'


  componentDidUpdate: (prevProps, prevState) ->

    element = React.findDOMNode this.refs.selectedItem
    emojify.run element


  onItemSelected: (index) ->

    ActivityFlux.actions.emoji.setCommonListSelectedIndex index


  onItemConfirmed: ->

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  close: ->

    ActivityFlux.actions.emoji.setCommonListVisibility no


  handleKeyDown: (event) ->

    return  unless @props.visible and event.which is ESC

    kd.utils.stopDOMEvent event
    @close()


  renderList: ->

    { items, itemsPerRow, selectedItem } = @props

    items.map (item, index) =>
      isFirstInRow = (index + 1) % itemsPerRow is 1
      isSelected   = selectedItem is item

      <EmojiSelectorItem
        item         = { item }
        index        = { index }
        isFirstInRow = { isFirstInRow }
        isSelected   = { isSelected }
        onSelected   = { kd.utils.throttle 300, @bound 'onItemSelected' }
        onConfirmed  = { @bound 'onItemConfirmed' }
        key          = { item }
      />


  render: ->

    { visible, selectedItem } = @props

    <Dropup
      className      = "EmojiSelector"
      visible        = { visible }
      onOuterClick   = { @bound 'close' }
    >
      <div className="EmojiSelector-list" ref="list">
        {@renderList()}
      </div>
      <div className="EmojiSelector-footer">
        <div className="EmojiSelector-selectedItemIcon" ref="selectedItem">
          {formatEmojiName selectedItem}
        </div>
        <div className="EmojiSelector-selectedItemName">
          {formatEmojiName selectedItem}
        </div>
        <div className="clearfix" />
      </div>
    </Dropup>
