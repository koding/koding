$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
classnames            = require 'classnames'
immutable             = require 'immutable'
emojify               = require 'emojify.js'
formatEmojiName       = require 'activity/util/formatEmojiName'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox/portaldropbox'
EmojiSelectorItem     = require 'activity/components/emojiselectoritem'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'
renderEmojiSpriteIcon = require 'activity/util/renderEmojiSpriteIcon'


module.exports = class EmojiSelector extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''


  componentDidUpdate: (prevProps, prevState) ->

    { visible } = @props
    return  unless visible

    list = React.findDOMNode this.refs.list
    emojify.run list, renderEmojiSpriteIcon


  updatePosition: (inputDimensions) -> @refs.dropbox.setInputDimensions inputDimensions


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


  renderSelectedItemIcon: ->

    { selectedItem } = @props
    icon = "<span class='emojiSpriteIcon emoji-#{selectedItem or 'cow'}' />"
    <div className="EmojiSelector-selectedItemIcon" dangerouslySetInnerHTML={__html: icon} />


  render: ->

    { visible, selectedItem } = @props

    <Dropbox
      className = 'EmojiSelector'
      visible   = { visible }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      right     = 0
      ref       = 'dropbox'
      resize    = 'custom'
    >
      <div className="EmojiSelector-list Dropbox-resizable" ref="list">
        {@renderList()}
        <div className='clearfix'></div>
      </div>
      <div className="EmojiSelector-footer">
        {@renderSelectedItemIcon()}
        <div className="EmojiSelector-selectedItemName">
          {if selectedItem then formatEmojiName selectedItem else 'Choose your emoji!'}
        </div>
        <div className="clearfix" />
      </div>
    </Dropbox>

