kd       = require 'kd'
ReactDOM = require 'react-dom'

module.exports = ListWithTabsMixin =

  sectionTabId: (sectionIndex) -> "#{@sectionId sectionIndex}-tab"


  scrollToSection: (sectionIndex) ->

    list = ReactDOM.findDOMNode @refs.list
    return list.scrollTop = 0  unless sectionIndex?

    sectionId  = @sectionId sectionIndex
    section    = $("##{sectionId}")
    sectionTop = section.position().top

    list.scrollTop += sectionTop

    selectedTab = document.getElementById @sectionTabId sectionIndex
    kd.utils.wait 10, => @selectTab selectedTab


  calculateSectionScrollData: ->

    { items } = @props

    sectionScrollData = items.map (sectionItem, sectionIndex) =>
      sectionId  = @sectionId sectionIndex
      section    = $("##{sectionId}")
      sectionTop = section.position().top
      sectionTab = document.getElementById @sectionTabId sectionIndex

      return { sectionTop, sectionTab }

    sectionScrollData  = sectionScrollData.toJS()
    @sectionScrollData = sectionScrollData


  resetSectionScrollData: -> @sectionScrollData = null  


  onScroll: ->

    return  unless @sectionScrollData

    list        = ReactDOM.findDOMNode @refs.list
    scrollTop   = list.scrollTop
    tabs        = ReactDOM.findDOMNode @refs.tabs
    selectedTab = tabs.querySelector '.allTab'

    for scrollItem, i in @sectionScrollData
      if scrollTop < scrollItem.sectionTop
        selectedTab = @sectionScrollData[i - 1].sectionTab  if i > 0
        break

    @selectTab selectedTab


  selectTab: (tab) ->

    tabs      = ReactDOM.findDOMNode @refs.tabs
    activeTab = tabs.querySelector '.activeTab'

    activeTab.classList.remove 'activeTab'  if activeTab

    tab.classList.add 'activeTab'

