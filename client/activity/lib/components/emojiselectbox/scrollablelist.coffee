$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
classnames           = require 'classnames'
immutable            = require 'immutable'
Scroller             = require 'app/components/scroller'
List                 = require './list'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class EmojiSelectBoxScrollableList extends React.Component

  @defaultProps =
    items        : immutable.List()
    query        : ''
    sectionIndex : 0


  componentDidMount: ->

    { items } = @props

    sectionPositions = items.map (sectionItem, sectionIndex) =>
      return 0  unless sectionIndex

      sectionAnchor = $(@refs.list.getSectionAnchorByIndex sectionIndex)
      sectionTop    = sectionAnchor.position().top
      return sectionTop

    sectionPositions  = sectionPositions.toJS()
    @sectionPositions = sectionPositions


  componentDidUpdate: (prevProps, prevState) ->

    { sectionIndex } = @props
    return  if prevProps.sectionIndex is sectionIndex
    return  unless @sectionPositions

    scroller  = ReactDOM.findDOMNode @refs.scroller
    scrollTop = scroller.scrollTop

    return scroller.scrollTop = 0  unless sectionIndex

    # this check avoids useless scrolling when section is changed
    # while user is scrolling the list with scrollbar
    isBelowCurrentSection = scrollTop >= @sectionPositions[sectionIndex]
    isAboveNextSection    = sectionIndex is @sectionPositions.length - 1 or @sectionPositions[sectionIndex + 1] > scrollTop
    return  if isBelowCurrentSection and isAboveNextSection

    # scrolling works only when user changes a section clicking on the tab
    kd.utils.defer =>
      scroller.scrollTop = @sectionPositions[sectionIndex]


  onScroll: ->

    return  unless @sectionPositions

    fixedHeader = ReactDOM.findDOMNode @refs.fixedHeader
    scroller    = ReactDOM.findDOMNode @refs.scroller
    scrollTop   = scroller.scrollTop

    isFixedHeaderVisible = scrollTop > @sectionPositions[0]
    fixedHeader.classList.toggle 'hidden', not isFixedHeaderVisible

    return  if @props.query

    sectionIndex  = 0
    positions = @sectionPositions
    for position, i in positions
      if scrollTop < position
        sectionIndex = i - 1  if i > 0
        break

    if sectionIndex is 0 and positions[positions.length - 1] <= scrollTop
      sectionIndex = positions.length - 1

    if sectionIndex isnt @props.sectionIndex
      @onSectionChange sectionIndex


  onSectionChange: (sectionIndex) -> @props.onSectionChange? sectionIndex


  onSearch: (event) ->

    { value }    = event.target
    { onSearch } = @props

    onSearch? value


  renderFixedCategoryHeader: ->

    { items, sectionIndex, query } = @props

    index    = if query then 0 else sectionIndex
    category = if index > 0 then items.get(index).get 'category' else ''

    <header
      className = 'EmojiSelectBox-categorySectionHeader fixedHeader hidden'
      ref       = 'fixedHeader'>
        {category}
    </header>


  render: ->

    { items, query } = @props

    <div>
      { @renderFixedCategoryHeader() }
      <Scroller className='EmojiSelectBox-list Dropbox-resizable' ref='scroller' onScroll={@bound 'onScroll'}>
        <input className='EmojiSelectBox-searchInput' placeholder='Search' value={query} onChange={@bound 'onSearch'} />
        <List
          items            = { items }
          onItemSelected   = { @props.onItemSelected }
          onItemUnselected = { @props.onItemUnselected }
          onItemConfirmed  = { @props.onItemConfirmed }
          showEmptySection = { query }
          ref              = 'list'
        />
      </Scroller>
    </div>


EmojiSelectBoxScrollableList.include [ImmutableRenderMixin]

