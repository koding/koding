kd                     = require 'kd'
React                  = require 'kd-react'
immutable              = require 'immutable'
classnames             = require 'classnames'
Dropbox                = require 'activity/components/dropbox/portaldropbox'
DropboxItem            = require 'activity/components/dropboxitem'
ErrorDropboxItem       = require 'activity/components/errordropboxitem'
SearchDropboxItem      = require 'activity/components/searchdropboxitem'
ScrollableDropboxMixin = require 'activity/components/dropbox/scrollabledropboxmixin'

module.exports = class SearchDropbox extends React.Component

  @propTypes =
    query           : React.PropTypes.string
    items           : React.PropTypes.instanceOf immutable.List
    selectedItem    : React.PropTypes.instanceOf immutable.Map
    selectedIndex   : React.PropTypes.number
    flags           : React.PropTypes.instanceOf immutable.Map
    onItemSelected  : React.PropTypes.func
    onItemConfirmed : React.PropTypes.func
    onClose         : React.PropTypes.func


  @defaultProps =
    query           : ''
    items           : immutable.List()
    selectedItem    : null
    selectedIndex   : 0
    flags           : null
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  shouldComponentUpdate: (nextProps, nextState) -> not nextProps.flags?.get 'isLoading'


  getItemKey: (item) -> item.getIn ['message', 'id']


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex, onItemSelected, onItemConfirmed } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <SearchDropboxItem
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
      { query } not found
    </ErrorDropboxItem>


  renderEmptyQueryMessage: ->

    <DropboxItem className="DropboxItem-singleLine">
      nothing found yet, continue typing...
    </DropboxItem>


  render: ->

    { items, query, flags } = @props

    isError      = items.size is 0 and query
    isEmptyQuery = not query

    <Dropbox
      className = 'SearchDropbox'
      visible   = { items.size > 0 or isError or isEmptyQuery }
      onClose   = { @props.onClose }
      type      = 'dropup'
      title     = 'Search'
      ref       = 'dropbox'
    >
      { @renderEmptyQueryMessage()  if isEmptyQuery }
      { @renderError()  if isError }
      { @renderList()  unless isError and isEmptyQuery }
    </Dropbox>


SearchDropbox.include [ ScrollableDropboxMixin ]

