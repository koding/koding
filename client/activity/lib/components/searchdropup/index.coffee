kd               = require 'kd'
React            = require 'kd-react'
immutable        = require 'immutable'
classnames       = require 'classnames'
ActivityFlux     = require 'activity/flux'
Dropup           = require 'activity/components/dropup'
SearchDropupItem = require 'activity/components/searchdropupitem'

KeyboardNavigatedDropup = require 'activity/components/dropup/keyboardnavigateddropup'
KeyboardScrolledDropup  = require 'activity/components/dropup/keyboardscrolleddropup'


module.exports = class SearchDropup extends React.Component

  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  getItemKey: (item) -> item.getIn ['message', 'id']


  close: -> ActivityFlux.actions.chatInputSearch.setVisibility no


  requestNextIndex: -> ActivityFlux.actions.chatInputSearch.moveToNextIndex()


  requestPrevIndex: -> ActivityFlux.actions.chatInputSearch.moveToPrevIndex()


  setQuery: (query) ->

    matchResult = query?.match /^\/s(.+)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.chatInputSearch.setQuery query
      ActivityFlux.actions.chatInputSearch.setVisibility yes
    else if @isActive()
      @close()


  onItemSelected: (index) ->

    ActivityFlux.actions.chatInputSearch.setSelectedIndex index


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected = item is selectedItem

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


React.Component.include.call SearchDropup, [KeyboardNavigatedDropup, KeyboardScrolledDropup]
