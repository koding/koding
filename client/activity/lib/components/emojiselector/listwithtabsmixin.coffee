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

    list = ReactDOM.findDOMNode @refs.list
    return  unless list
    return list.scrollTop = 0  if tabIndex is -1

    kd.utils.defer =>
      sectionId  = @sectionId tabIndex
      section    = $("##{sectionId}")
      sectionTop = section.position().top

      list.scrollTop += sectionTop


  ###*
   * Calculates scroll positions of sections and caches it in @sectionScrollData.
   * This data is used when it's necessary to check if we need to activate another tab
   * while scrolling the list. Caching helps to avoid performance problems while scrolling
  ###
  calculateSectionScrollData: ->

    { items } = @props

    sectionScrollData = items.map (sectionItem, sectionIndex) =>
      sectionId  = @sectionId sectionIndex
      section    = $("##{sectionId}")
      sectionTop = section.position().top

      return { sectionTop }

    sectionScrollData  = sectionScrollData.toJS()
    @sectionScrollData = sectionScrollData


  ###*
   * Checks if we need to activate another tab while scrolling.
   * If so, it sets @dontScrollOnTabIndexChange to yes to avoid
   * extra scrolling when tabIndex is updated and calls action
   * to set new tab index
  ###
  onScroll: ->

    return  unless @sectionScrollData

    list      = ReactDOM.findDOMNode @refs.list
    scrollTop = list.scrollTop
    tabIndex  = -1

    for scrollItem, i in @sectionScrollData
      if scrollTop < scrollItem.sectionTop
        tabIndex = i - 1  if i > 0
        break

    @dontScrollOnTabIndexChange = yes  unless tabIndex is @props.tabIndex
    @setTabIndex tabIndex

