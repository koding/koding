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
      @setTooltip
        gravity : @getOption 'tooltipPosition'
        cssClass : 'reply-like-tooltip'
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

      wrapName = (name) -> "<p>#{name}</p>"
      names = accounts.map (acc) ->
        wrapName KD.utils.getFullnameFromAccount acc

      @updateTooltip names

  updateTooltip: (names) ->

    { length } = names

    return unless length > 0

    upperLimit = 20
    andMore    = ""

    if length > upperLimit
      names = names.splice 0, upperLimit
      andMore = "<p>and #{length - upperLimit} more...</p>"

    title = "#{names.join ''}#{andMore}"

    @getTooltip().update {title}


  fetchAccounts: (callback) ->

    { socialapi } = KD.singletons

    socialapi.message.listLikers { id: @getData().id }, (err, res) =>
      actorsPreview = res

      return callback null, actorsPreview  unless actorsPreview.length

      constructorName = "JAccount"
      origins = actorsPreview.map (id) -> {id, constructorName}

      KD.remote.cacheable origins, callback


  pistachio: -> ''

