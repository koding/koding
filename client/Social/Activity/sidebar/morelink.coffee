class SidebarMoreLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.title       or= 'More...'
    options.searchClass or= SidebarSearchModal
    options.cssClass      = KD.utils.curry 'more-link', options.cssClass

    super options, data

    @updateCount()


  updateCount: (visibleCount) ->

    @setOption 'visibleCount', visibleCount  if visibleCount
    {countSource} = @getOptions()

    countSource @bound 'renderCount'  if countSource


  renderCount: (err, res) ->

    return  if err

    { visibleCount, limit } = @getOptions()
    { totalCount }          = res

    if totalCount > limit
    then @show()
    else @hide()


