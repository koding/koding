kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
ActivityFlux         = require 'activity/flux'
Dropup               = require 'activity/components/dropup'
SearchDropupItem     = require 'activity/components/searchdropupitem'
DropupWrapperMixin   = require 'activity/components/dropup/dropupwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class SearchDropup extends React.Component

  @include [ ImmutableRenderMixin, DropupWrapperMixin ]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedItem   : null
    selectedIndex  : 0


  formatSelectedValue: -> @props.selectedItem.get('message').toJS()


  getItemKey: (item) -> item.getIn ['message', 'id']


  close: ->

    ActivityFlux.actions.chatInputSearch.setVisibility no
    ActivityFlux.actions.chatInputSearch.resetData()


  moveToNextPosition: (keyInfo) ->

    return no  if keyInfo.isRightArrow

    ActivityFlux.actions.chatInputSearch.moveToNextIndex()  unless @hasSingleItem()
    return yes


  moveToPrevPosition: (keyInfo) ->

    return no  if keyInfo.isLeftArrow

    ActivityFlux.actions.chatInputSearch.moveToPrevIndex()  unless @hasSingleItem()
    return yes


  checkTextForQuery: (textData) ->

    { value } = textData

    matchResult = value.match /\/s (.+)/
    return no  unless matchResult

    query = matchResult[1]
    ActivityFlux.actions.chatInputSearch.setQuery query
    ActivityFlux.actions.chatInputSearch.setVisibility yes
    return yes


  onItemSelected: (index) ->

    ActivityFlux.actions.chatInputSearch.setSelectedIndex index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <SearchDropupItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    <Dropup
      className      = "SearchDropup"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropup'
    >
      <div className="Dropup-innerContainer">
        {@renderList()}
      </div>
    </Dropup>

