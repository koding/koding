class ActivityLikeCount extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "like-count", options.cssClass

    super options, data

    data
      .on 'LikeAdded', @bound 'update'
      .on 'LikeRemoved', @bound 'update'


  click: (event) ->

    KD.utils.stopDOMEvent event

    data = @getData()
    {isInteracted, actorsPreview} = data.interactions.like

    return  unless isInteracted

    @fetchAccounts (err, accounts) =>

      return KD.showError err  if err
      new ShowMoreDataModalView title: "", accounts


  mouseEnter: ->

    {actorsCount, actorsPreview} = @getData().interactions.like

    return @unsetClass "liked"  if actorsCount is 0

    @getTooltip().update title: "Loading..."

    @fetchAccounts (err, accounts) =>

      return KD.showError err  if err
      return  unless accounts

      names  = []
      strong = (x) -> "<strong>#{x}</strong>"

      for account in accounts
        name = KD.utils.getFullnameFromAccount account
        names.push "#{strong name}"

      @updateTooltip names


  updateTooltip: (names) ->

    {actorsCount} = @getData().interactions.like

    if actorsCount > 3
      sep = ", "
      andMore = "and <strong>#{actorsCount - 3} more.</strong>"
    else
      sep = " and "
      andMore = ""

    title =
      switch actorsCount
        when 0 then ""
        when 1 then "#{names[0]}"
        when 2 then "#{names[0]} and #{names[1]}"
        else "#{names[0]}, #{names[1]}#{sep}#{names[2]} #{andMore}"

    @getTooltip().update {title}


  fetchAccounts: (callback) ->

    {actorsPreview} = @getData().interactions.like

    return callback null, actorsPreview  unless actorsPreview.length

    constructorName = "JAccount"
    origins = actorsPreview.map (id) -> {id, constructorName}

    KD.remote.cacheable origins, callback


  update: ->

    {actorsCount} = @getData().interactions.like
    if actorsCount then @show() else @hide()

    @updatePartial actorsCount


  viewAppended: ->

    super

    @update()


  pistachio: -> ""
