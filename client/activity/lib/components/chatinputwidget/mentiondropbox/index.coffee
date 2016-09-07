kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
PortalDropbox        = require 'activity/components/dropbox/portaldropbox'
UserMentionItem      = require './useritem'
ChannelMentionItem   = require './channelitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
ScrollableDropbox    = require 'activity/components/dropbox/scrollabledropbox'

class MentionDropbox extends React.Component

  @propTypes =
    query           : React.PropTypes.string
    userMentions    : React.PropTypes.instanceOf immutable.List
    channelMentions : React.PropTypes.instanceOf immutable.List
    selectedItem    : React.PropTypes.instanceOf immutable.Map
    selectedIndex   : React.PropTypes.number
    onItemSelected  : React.PropTypes.func
    onItemConfirmed : React.PropTypes.func
    onClose         : React.PropTypes.func


  @defaultProps =
    query           : ''
    userMentions    : immutable.List()
    channelMentions : immutable.List()
    selectedItem    : null
    selectedIndex   : 0
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  getItemKey: (item) ->

    names = item.get('names')
    if names then names.first() else item.get '_id'


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderUserMentions: ->

    { userMentions, selectedIndex, query, onItemSelected, onItemConfirmed } = @props

    userMentions.map (item, index) =>
      isSelected = index is selectedIndex

      <UserMentionItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { @getItemKey item }
        query       = { query }
      />


  renderChannelMentions: ->

    { userMentions, channelMentions, selectedIndex, query, onItemSelected, onItemConfirmed } = @props

    channelMentions.map (item, index) =>
      index += userMentions.size
      isSelected = index is selectedIndex

      <ChannelMentionItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { @getItemKey item }
        query       = { query }
      />


  render: ->

    { userMentions, channelMentions } = @props

    <PortalDropbox
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
    </PortalDropbox>


  helper =

    renderListHeader: (title) ->

      <div className='Dropbox-header MentionDropbox-listHeader DropboxItem-separated'>
        { title }
      </div>


MentionDropbox.include [ ImmutableRenderMixin ]

module.exports = ScrollableDropbox MentionDropbox
