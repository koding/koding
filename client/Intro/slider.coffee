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
