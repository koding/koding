class Page extends JView

  constructor:(options={}, data)->
    options.cssClass = KD.utils.curry 'kd-page', options.cssClass
    super options, data

  viewAppended:->
    super

    @addSubView title = new KDCustomHTMLView
      partial : @getOptions().content

    title.setStyle
      position   : 'absolute'
      marginLeft : '-80px'
      marginTop  : '-15px'
      color      : 'white'
      fontSize   : '30px'
      top        : '50%'
      left       : '50%'

class Slider extends JView

  [X_COORD, Y_COORD] = [1, 2]

  @directions        =
    leftToRight      : ['left', 'top']
    topToBottom      : ['top', 'left']

  constructor:(options={}, data)->

    options.cssClass = KD.utils.curry 'kd-slide', options.cssClass
    options.scale    = 0.8

    super options, data

    @pages     = []
    @_coordsY  = []
    @_currentX = 0

    [@_pd, @_spd] = options.directions ? @constructor.directions.leftToRight

  addPage:(page)->
    @addSubView page

    stack = 100 * (@pages.length)
    pref  = {}
    pref[@_pd] = "#{stack}%"
    page.setStyle pref
    @pages.push [page]
    @_coordsY.push 0

  addSubPage:(page)->
    @addSubView page

    lastAddedPage = @pages.last
    stack = 100 * lastAddedPage.length
    pref  = {}
    pref[@_spd] = "#{stack}%"
    page.setStyle pref
    lastAddedPage.push page

  nextPage:->
    @jump @_currentX + 1, X_COORD
  previousPage:->
    @jump @_currentX - 1, X_COORD

  nextSubPage:->
    @jump @_coordsY[@_currentX] + 1, Y_COORD
  previousSubPage:->
    @jump @_coordsY[@_currentX] - 1, Y_COORD

  jump:(pageIndex, coord)->

    if coord is X_COORD
      pages   = @pages
      current = @_currentX
      key     = @_pd
    else
      pages   = @pages[@_currentX]
      current = @_coordsY[@_currentX]
      key     = @_spd

    return if pages.length <= 1

    # Poor man's index limitter, max pages.length - min 0
    index = Math.min pages.length - 1, Math.max 0, pageIndex
    direction = if index < current then 100 else -100

    pref = {}
    pref[key] = "#{direction}%"
    scale = @getOption 'scale'
    props = ['webkitTransform', 'MozTransform', 'transform']
    pref[prop] = "scale(#{scale})"  for prop in props

    if coord is X_COORD
      currentPage = pages[current][@_coordsY[current]]
      newPage     = pages[index][@_coordsY[index]]
      @_currentX  = index
    else
      currentPage = pages[current]
      newPage     = pages[index]
      @_coordsY[@_currentX] = index

    currentPage.setCss pref
    pref[key] = 0
    newPage.setCss     pref

    @utils.wait 800, ->
      pref[prop] = "scale(1)"  for prop in props
      newPage.setCss pref

class DemosMainView extends KDScrollView

  viewAppended:->

    KD.getSingleton("mainView").enableFullscreen()

    @addSubView @slider = new Slider
      directions : Slider.directions.topToBottom

    @slider.addPage page1 = new Page
      content  : 'Page 1'
    page1.setCss backgroundColor : '#518e2f'

    @slider.addPage page2 = new Page
      content  : 'Page 2'
    page2.setCss backgroundColor : '#b6a43c'

    @slider.addSubPage page10 = new Page
      content  : 'Subpage #1 of Page 2'
    page10.setCss backgroundColor : '#ff9200'

    @slider.addSubPage page11 = new Page
      content  : 'Subpage #2 of Page 2'
    page11.setCss backgroundColor : '#fff200'

    @slider.addSubPage page12 = new Page
      content  : 'Subpage #3 of Page 2'
    page12.setCss backgroundColor : '#ff0900'

    @slider.addPage page3 = new Page
      content  : 'Page 3'
    page3.setCss backgroundColor : '#309063'

    @slider.addSubPage page13 = new Page
      content  : 'Subpage #1 of Page 3'
    page13.setCss backgroundColor : '#0ff900'

    @addSubView nextButton = new KDButtonView
      cssClass : 'next'
      title    : 'Next Page'
      callback : => @slider.nextPage()

    nextButton.setStyle
      position : 'absolute'
      right    : '10px'
      bottom   : '10px'

    @addSubView prevButton = new KDButtonView
      cssClass : 'prev'
      title    : 'Previous Page'
      callback : => @slider.previousPage()

    prevButton.setStyle
      position : 'absolute'
      left     : '10px'
      bottom   : '10px'

    @addSubView previousSubPageButton = new KDButtonView
      cssClass : 'Down'
      title    : 'Previous SubPage'
      callback : => @slider.previousSubPage()

    previousSubPageButton.setStyle
      position : 'absolute'
      left     : '200px'
      bottom   : '10px'

    @addSubView nextSubPageButton = new KDButtonView
      cssClass : 'up'
      title    : 'Next SubPage'
      callback : => @slider.nextSubPage()

    nextSubPageButton.setStyle
      position : 'absolute'
      right    : '200px'
      bottom   : '10px'
