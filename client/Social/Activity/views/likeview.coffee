class ActivityLikeView extends JView

  constructor: (options = {}, data) ->

    options.tagName            or= 'span'
    options.cssClass           or= 'like-view'
    options.tooltipPosition    or= 'se'
    options.checkIfLikedBefore  ?= no
    options.useTitle            ?= yes

    super options, data

    @_currentState = no

    @likeCount    = new ActivityLikeCount
      tooltip     :
        gravity   : options.tooltipPosition
        title     : ""
    , data

    @likeLink = new ActivityLikeLink {}, data

    {useTitle}     = @getOptions()
    {isInteracted} = data.interactions.like

    @_currentState = isInteracted

    if isInteracted
    then @decorateLike no
    else @decorateUnlike no


  toggleState: (err) ->

    return @showError err  if err

    @_currentState = not @_currentState

    if @_currentState
    then @decorateLike()
    else @decorateUnlike()


  decorateLike: (track = yes) ->

    @setClass "liked"
    @likeLink.updatePartial "Unlike"  if @getOption "useTitle"

    return  unless track

    KD.mixpanel "Activity like, success"

    KD.getSingleton("badgeController").checkBadge
      source : "JNewStatusUpdate" , property : "likes", relType : "like", targetSelf : 1


  decorateUnlike: (track = yes) ->

    @unsetClass "liked"
    @likeLink.updatePartial "Like" if @getOption "useTitle"

    return  unless track

    KD.mixpanel "Activity unlike, success"


  showError: (err) ->

    KD.showError err,
      AccessDenied : "You are not allowed to like activities"
      KodingError  : "Something went wrong"


  pistachio: ->

    """{{> @likeLink}}{{> @likeCount}}"""
