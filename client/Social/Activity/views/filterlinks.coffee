class FilterLinksView extends KDCustomHTMLView
  constructor: (options = {}, data) ->
    options.cssClass    = KD.utils.curry 'filter-links', options.cssClass
    options.tagName     = 'nav'
    super options, data

    @links              = {}
    @activeLink         = null

    for title, linkData of @data
      @addLink title, linkData

    return this

  addLink : (title, data) ->
    view = new KDCustomHTMLView
      tagName    : 'a'
      partial    : title
      click      : =>
        @setActive title
        @emit 'filterLinkClicked', data
    ,
      data

    @links[title] = view
    @addSubView view

    if data.active then @setActive title

    return view

  setActive : (title) ->
    return unless @links[title]
    return if @activeLink is @links[title]

    for k, view of @links
      view.unsetClass 'active'

    @links[title].setClass 'active'

    @activeLink = @links[title]

    return @links[title]

