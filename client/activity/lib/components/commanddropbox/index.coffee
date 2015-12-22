kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
CommandDropboxItem   = require 'activity/components/commanddropboxitem'
ErrorDropboxItem     = require 'activity/components/errordropboxitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class CommandDropbox extends React.Component

  @defaultProps =
    query           : ''
    items           : immutable.List()
    selectedItem    : null
    selectedIndex   : 0
    flags           : null
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  getItemKey: (item) -> item.get 'name'


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex, onItemSelected, onItemConfirmed } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <CommandDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  renderError: ->

    { query } = @props

    <ErrorDropboxItem>
      { query } is not a proper command
    </ErrorDropboxItem>


  render: ->

    { items, query, visible, onClose } = @props

    isError = items.size is 0 and query

    <Dropbox
      className = 'CommandDropbox'
      visible   = { query? }
      onClose   = { onClose }
      type      = 'dropup'
      title     = 'Commands matching'
      subtitle  = { query }
      ref       = 'dropbox'
    >
      { @renderList()  unless isError }
      { @renderError()  if isError }
    </Dropbox>


CommandDropbox.include [ ImmutableRenderMixin ]

