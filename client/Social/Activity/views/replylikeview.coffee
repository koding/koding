class ReplyLikeView extends ActivityLikeLink

  constructor: (options = {}, data) ->

    options.tooltipPosition    or= 'se'
    options.useTitle            ?= yes

    super options, data

    @update()


  update: ->

    {isInteracted, actorsCount} = @getData().interactions.like

    if isInteracted
    then @setClass 'liked'
    else @unsetClass 'liked'

    if actorsCount > 0
      @setClass 'has-likes'
      @setTooltip gravity : @getOption 'tooltipPosition'
    else
      @unsetClass 'has-likes'
      @unsetTooltip()

  mouseEnter: ->
    { actorsCount, actorsPreview } = @getData().interactions.like

    return unless actorsCount > 0

    @getTooltip().update title: "Loading..."

    @fetchAccounts (err, accounts) =>

      return KD.showError err if err
      return unless accounts

      strong = (x) -> "<strong>#{x}</strong>"
      names = accounts.map (acc) ->
        strong KD.utils.getFullnameFromAccount acc

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

  pistachio: -> ''

