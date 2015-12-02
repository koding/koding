kd                   = require 'kd'
React                = require 'kd-react'
DropboxItem          = require 'activity/components/dropboxitem'
EmojiIcon            = require 'activity/components/emojiicon'
ImmutableRenderMixin = require 'react-immutable-render-mixin'

module.exports = class EmojiSelectBoxItem extends React.Component

  @include [ ImmutableRenderMixin ]

  @defaultProps =
    item         : ''
    index        : 0


  constructor: (props) ->

    super props
    @state = { isSelected : no }


  onSelected: ->

    @setState { isSelected : yes }

    { onSelected, index } = @props
    onSelected? index


  onUnselected: ->

    @setState { isSelected : no }
    @props.onUnselected?()


  render: ->

    { item }       = @props
    { isSelected } = @state

    <DropboxItem
      isSelected   = { isSelected }
      onSelected   = { @bound 'onSelected' }
      onUnselected = { @bound 'onUnselected' }
      onConfirmed  = { @props.onConfirmed }
      className    = 'EmojiSelectBoxItem'>
        <EmojiIcon emoji={item} />
    </DropboxItem>

