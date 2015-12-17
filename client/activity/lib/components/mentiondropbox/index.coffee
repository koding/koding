kd                     = require 'kd'
React                  = require 'kd-react'
immutable              = require 'immutable'
classnames             = require 'classnames'
Dropbox                = require 'activity/components/dropbox/portaldropbox'
UserMentionItem        = require 'activity/components/mentiondropboxitem/usermentionitem'
ChannelMentionItem     = require 'activity/components/mentiondropboxitem/channelmentionitem'
ImmutableRenderMixin   = require 'react-immutable-render-mixin'


module.exports = class MentionDropbox extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    selectedIndex   : 0
    selectedItem    : null


  getItemKey: (item) ->

    names = item.get('names')

    if names then names.first() else item.get '_id'


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderUserMentions: ->

    { items, selectedIndex, query } = @props

    { userMentions } = items

    userMentions.map (item, index) =>
      isSelected = index is selectedIndex

      <UserMentionItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @props.onItemSelected }
        onConfirmed = { @props.onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
        query       = { query }
      />


  renderChannelMentions: ->

    { items, channelMentions, selectedIndex, query } = @props

    { userMentions, channelMentions } = items

    channelMentions.map (item, index) =>
      index += userMentions.size
      isSelected = index is selectedIndex

      <ChannelMentionItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @props.onItemSelected }
        onConfirmed = { @props.onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
        query       = { query }
      />


  render: ->

    { userMentions, channelMentions } = @props.items

    <Dropbox
      className = 'MentionDropbox'
      visible   = { userMentions.size + channelMentions.size > 0 }
      onClose   = { @props.onClose }
      type      = 'dropup'
      ref       = 'dropbox'
    >
      { helper.renderListHeader 'People'  if userMentions.size > 0 }
      { @renderUserMentions() }
      { helper.renderListHeader 'Groups'  if channelMentions.size > 0 }
      { @renderChannelMentions() }
    </Dropbox>


  helper =

    renderListHeader: (title) ->

      <div className='Dropbox-header MentionDropbox-listHeader DropboxItem-separated'>
        { title }
      </div>

