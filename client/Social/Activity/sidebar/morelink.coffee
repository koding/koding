class SidebarMoreLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.title       or= "More..."
    options.searchClass or= SidebarSearchModal
    options.cssClass      = KD.utils.curry 'more-link', options.cssClass

    super options, data

    {countSource} = @getOptions()

    countSource @bound 'renderCount'  if countSource

  renderCount: (err, res) ->
    return if err

    options = @getOptions()
    {title, limit} = options
    {totalCount} = res
    if totalCount > limit then @show() else @hide()
    totalCount -= limit

    data = @getData()
    data.title = "+#{totalCount} #{title}"
    @render()
