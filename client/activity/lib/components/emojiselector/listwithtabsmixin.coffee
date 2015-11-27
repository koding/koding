kd       = require 'kd'
ReactDOM = require 'react-dom'

###*
 * Mixin to handle interaction of tabs and sections:
 * - when user clicks on tab, list should scroll to corresponding section
 * - when user scrolls list and gets to the next section, corresponding tab
 * should become active
###
module.exports = ListWithTabsMixin =

  ###*
   * If tabIndex is changed, we need to scroll to corresponding section.
   * We don't need to scroll, if action was fired by scrolling the list,
   * i.e. when dontScrollOnTabIndexChange is yes
  ###
  componentDidUpdate: (prevProps, prevState) ->

    { tabIndex } = @props
    return  if prevProps.tabIndex is tabIndex

    dontScrollOnTabIndexChange = @dontScrollOnTabIndexChange
    @dontScrollOnTabIndexChange = no
    return  if dontScrollOnTabIndexChange

    list = ReactDOM.findDOMNode @refs.scrollable
    return  unless list
    return list.scrollTop = 0  if tabIndex is -1

    kd.utils.defer =>
      list.scrollTop = @sectionPositions[tabIndex]  if @sectionPositions


  ###*
   * Calculates scroll positions of sections and caches it in @sectionPositions.
   * This data is used when it's necessary to check if we need to activate another tab
   * while scrolling the list. Caching helps to avoid performance problems while scrolling
  ###
  calculateSectionPositions: ->

    { items } = @props

    sectionPositions = items.map (sectionItem, sectionIndex) =>
      sectionId  = @sectionId sectionIndex
      section    = $("##{sectionId}")
      sectionTop = section.position().top

      return sectionTop

    sectionPositions  = sectionPositions.toJS()
    @sectionPositions = sectionPositions


  ###*
   * Checks if fixed header should be visible depending on scroll position.
   * Also, checks if we need to highlight another tab while scrolling.
   * If so, it sets @dontScrollOnTabIndexChange to yes to avoid
   * extra scrolling when tabIndex is updated and calls action
   * to set new tab index.
   * Tab highlighting can be enabled/disabled using @isTabHighlightingEnabled()
  ###
  onScroll: ->

    return  unless @sectionPositions

    fixedHeader = ReactDOM.findDOMNode @refs.fixedHeader
    list        = ReactDOM.findDOMNode @refs.scrollable
    scrollTop   = list.scrollTop

    isFixedHeaderVisible = scrollTop > @sectionPositions[0]
    fixedHeader.classList.toggle 'hidden', not isFixedHeaderVisible

    return  unless @isTabHighlightingEnabled()

    tabIndex  = -1
    positions = @sectionPositions
    for position, i in positions
      if scrollTop < position
        tabIndex = i - 1  if i > 0
        break

    if tabIndex is -1 and positions[positions.length - 1] <= scrollTop
      tabIndex = positions.length - 1

    @dontScrollOnTabIndexChange = yes  unless tabIndex is @props.tabIndex
    @setTabIndex tabIndex

