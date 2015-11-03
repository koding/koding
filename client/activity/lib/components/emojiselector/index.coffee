$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
classnames            = require 'classnames'
immutable             = require 'immutable'
formatEmojiName       = require 'activity/util/formatEmojiName'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox/portaldropbox'
EmojiSelectorItem     = require 'activity/components/emojiselectoritem'
EmojiIcon             = require 'activity/components/emojiicon'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'


module.exports = class EmojiSelector extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''


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
      isSelected = selectedItem is item

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
      type      = 'dropup'
      right     = 0
      ref       = 'dropbox'
      resize    = 'custom'
    >
      <div className="EmojiSelector-list Dropbox-resizable">
        {@renderList()}
        <div className='clearfix'></div>
      </div>
      <div className="EmojiSelector-footer">
        <span className="EmojiSelector-selectedItemIcon">
          <EmojiIcon emoji={selectedItem or 'cow'} />
        </span>
        <div className="EmojiSelector-selectedItemName">
          {if selectedItem then formatEmojiName selectedItem else 'Choose your emoji!'}
        </div>
        <div className="clearfix" />
      </div>
    </Dropbox>

