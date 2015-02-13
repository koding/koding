class FilterLinksView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'filter-links', options.cssClass
    options.tagName  = 'nav'

    super options, data

    @links = {}

    @addLink name  for name in options.filters
    @selectFilter options.default


  addLink: (name) ->

    @addSubView @links[name] = new KDCustomHTMLView
      tagName : 'a'
      partial : name
      click   : @lazyBound 'selectFilter', name


  selectFilter: (name) ->

    return  if name is @selected
    return  unless @links[name]

    @links[@selected]?.unsetClass 'active'
    @links[@selected = name].setClass 'active'
    @emit 'FilterSelected', @selected
