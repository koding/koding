kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
DropboxItem          = require 'activity/components/dropboxitem'
ErrorDropboxItem     = require 'activity/components/errordropboxitem'
SearchDropboxItem    = require 'activity/components/searchdropboxitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class SearchDropbox extends React.Component

  @include [ ImmutableRenderMixin ]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedItem   : null
    selectedIndex  : 0
    flags          : immutable.Map()


  shouldComponentUpdate: (nextProps, nextState) -> not nextProps.flags?.get 'isLoading'


  getItemKey: (item) -> item.getIn ['message', 'id']


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <SearchDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @props.onItemSelected }
        onConfirmed = { @props.onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  renderError: ->

    { query } = @props

    <ErrorDropboxItem>
      { query } not found
    </ErrorDropboxItem>


  renderEmptyQueryMessage: ->

    <DropboxItem className="DropboxItem-singleLine">
      nothing found yet, continue typing...
    </DropboxItem>


  render: ->

    { items, query, flags, visible } = @props

    isError      = items.size is 0 and query
    isEmptyQuery = not query and visible

    <Dropbox
      className = 'SearchDropbox'
      visible   = { items.size > 0 }
      onClose   = { @props.onClose }
      type      = 'dropup'
      title     = 'Search'
      ref       = 'dropbox'
    >
      { @renderEmptyQueryMessage()  if isEmptyQuery }
      { @renderError()  if isError }
      { @renderList()  unless isError and isEmptyQuery }
    </Dropbox>

