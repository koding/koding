class ActivityLikeCount extends CustomLinkView

  click: (event) ->

    KD.utils.stopDOMEvent event

    data = @getData()
    {interactions: {like: {isInteracted, actorsPreview}}} = @getData()

    return  unless isInteracted

    @fetchAccounts (err, accounts) =>

      return KD.showError err  if err

      new ShowMoreDataModalView title: "", accounts


  mouseEnter: ->

    data = @getData()
    {interactions: {like}} = data
    {actorsCount, actorsPreview} = like

    return @unsetClass "liked"  if actorsCount is 0

    @getTooltip().update title: "Loading..."

    @fetchAccounts (err, accounts) =>

      return KD.showError err  if err

      return  unless accounts

      names = []

      strong = (x) -> "<strong>#{x}</strong>"

      for account in accounts
        name = KD.utils.getFullnameFromAccount account
        names.push "#{strong name}"

      if actorsCount > 3
        sep = ", "
        andMore = "and <strong>#{actorsCount - 3} more.</strong>"
      else
        sep = " and "
        andMore = ""

      @updateTooltip names


  updateTooltip: (names) ->

    {interactions: {like: {actorsCount}}} = @getData()

    tooltip =
      switch actorsCount
        when 0 then ""
        when 1 then "#{names[0]}"
        when 2 then "#{names[0]} and #{names[1]}"
        else "#{names[0]}, #{names[1]}#{sep}#{names[2]} #{andMore}"

    @getTooltip().update { title: tooltip }


  fetchAccounts: (callback) ->

    constructorName = "JAccount"
    origins = actorsPreview.map (id) -> {id, constructorName}

    KD.remote.cacheable origins, callback


  viewAppended: ->

    super

    {interactions: {like: {actorsCount}}} = @getData()
    if actorsCount then @show() else @hide()


  pistachio: ->

    "{{ #(interactions.like.actorsCount)}}"
