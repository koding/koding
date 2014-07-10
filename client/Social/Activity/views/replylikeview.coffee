class ReplyLikeView extends ActivityLikeLink

  constructor: (options = {}, data) ->

    options.tooltipPosition    or= 'se'
    options.useTitle            ?= yes

    super options, data

    @update()


  update: ->

    {isInteracted, actorsCount} = @getData().interactions.like

    if @getData().interactions.like.isInteracted
    then @setClass 'liked'
    else @unsetClass 'liked'

    if actorsCount > 0
    then @setClass 'has-likes'
    else @unsetClass 'has-likes'


  pistachio: -> ''