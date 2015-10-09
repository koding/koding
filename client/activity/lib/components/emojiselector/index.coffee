$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
classnames            = require 'classnames'
immutable             = require 'immutable'
emojify               = require 'emojify.js'
formatEmojiName       = require 'activity/util/formatEmojiName'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox'
EmojiSelectorItem     = require 'activity/components/emojiselectoritem'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'
renderEmojiSpriteIcon = require 'activity/util/renderEmojiSpriteIcon'


module.exports = class EmojiSelector extends React.Component

  ESC = 27


  @include [ImmutableRenderMixin]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''


  componentDidMount: ->

    document.addEventListener 'keydown',   @bound 'handleKeyDown'

    element = React.findDOMNode this.refs.list
    emojify.run element, renderEmojiSpriteIcon


  componentWillUnmount: ->

    document.removeEventListener 'keydown',   @bound 'handleKeyDown'


  componentDidUpdate: (prevProps, prevState) ->

    element = React.findDOMNode this.refs.selectedItem
    emojify.run element, renderEmojiSpriteIcon


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setCommonListSelectedIndex stateId, index


  onItemConfirmed: ->

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setCommonListVisibility stateId, no


  handleKeyDown: (event) ->

    return  unless @props.visible and event.which is ESC

    kd.utils.stopDOMEvent event
    @close()


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected   = selectedItem is item

      <EmojiSelectorItem
        item         = { item }
        index        = { index }
        isSelected   = { isSelected }
        onSelected   = { @bound 'onItemSelected' }
        onConfirmed  = { @bound 'onItemConfirmed' }
        key          = { item }
      />


  render: ->

    { visible, selectedItem } = @props

    <Dropbox
      className = 'EmojiSelector'
      visible   = { visible }
      onClose   = { @bound 'close' }
      direction = 'up'
    >
      <div className="EmojiSelector-list" ref="list">
        {@renderList()}
        <div className='clearfix'></div>
      </div>
      <div className="EmojiSelector-footer">
        <div className="EmojiSelector-selectedItemIcon" ref="selectedItem">
          {formatEmojiName(selectedItem or 'cow')}
        </div>
        <div className="EmojiSelector-selectedItemName">
          {if selectedItem then formatEmojiName selectedItem else 'Choose your emoji!'}
        </div>
        <div className="clearfix" />
      </div>
    </Dropbox>

