class SidebarMoreLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.title       or= 'More...'
    options.searchClass or= SidebarSearchModal
    options.cssClass      = KD.utils.curry 'more-link', options.cssClass

    super options, data

    @updateCount()


  updateCount: KD.utils.debounce 300, (visibleCount)->

    @setOption 'visibleCount', visibleCount  if visibleCount
    {countSource} = @getOptions()

    countSource @bound 'renderCount'  if countSource


  renderCount: (err, res) ->

    return if err

    options                      = @getOptions()
    {title, limit, visibleCount} = options
    {totalCount}                 = res
    limit                        = visibleCount  if visibleCount

    if totalCount > limit then @show() else @hide()

    data = @getData()
    data.title = "+#{totalCount - limit} #{title}"
    @render()
