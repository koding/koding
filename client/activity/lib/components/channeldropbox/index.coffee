kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox'
ChannelDropboxItem   = require 'activity/components/channeldropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux        = require 'activity/flux/chatinput'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class ChannelDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null


  formatSelectedValue: -> "##{@props.selectedItem.get 'name'}"


  getItemKey: (item) -> item.get 'id'


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.channel.setVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.channel.moveToNextIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.channel.moveToPrevIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^#(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.channel.setQuery stateId, query
    ChatInputFlux.actions.channel.setVisibility stateId, yes
    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.channel.setSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <ChannelDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    <Dropbox
      className    = 'ChannelDropbox'
      visible      = { @isActive() }
      onOuterClick = { @bound 'close' }
      direction    = 'up'
      ref          = 'dropbox'
    >
      <div className="Dropbox-innerContainer">
        <div className="Dropbox-header">
          Channels
        </div>
        <div className="ChannelDropbox-list">
          {@renderList()}
        </div>
      </div>
    </Dropbox>

