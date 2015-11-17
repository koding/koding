kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
CommandDropboxItem   = require 'activity/components/commanddropboxitem'
ErrorDropboxItem     = require 'activity/components/errordropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux        = require 'activity/flux/chatinput'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
isWithinCodeBlock    = require 'app/util/isWithinCodeBlock'


module.exports = class CommandDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null


  isActive: -> @props.visible


  formatSelectedValue: ->

    { selectedItem } = @props
    return ''  unless selectedItem

    return "#{selectedItem.get 'name'} #{selectedItem.get 'paramPrefix', ''}"


  getItemKey: (item) -> item.get 'name'


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.command.setVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.command.moveToNextIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.command.moveToPrevIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord, value, position } = textData
    return no  unless currentWord

    matchResult = value.match /^(\/[^\s]*)$/

    return no  unless matchResult
    return no  if isWithinCodeBlock value, position

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.command.setQuery stateId, query
    ChatInputFlux.actions.command.setVisibility stateId, yes
    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.command.setSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <CommandDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  renderError: ->

    { query } = @props

    <ErrorDropboxItem>
      { query } is not a proper command
    </ErrorDropboxItem>


  render: ->

    { items, query, visible } = @props

    isError = items.size is 0 and query

    <Dropbox
      className = 'CommandDropbox'
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      title     = 'Commands matching'
      subtitle  = { query }
      ref       = 'dropbox'
    >
      { @renderList()  unless isError }
      { @renderError()  if isError }
    </Dropbox>

