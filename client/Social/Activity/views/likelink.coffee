class ActivityLikeLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "action-link like-link", options.cssClass

    @state = data.interactions.like.isInteracted

    super options, data


  click: ->

    {id}           = data = @getData()
    {like, unlike} = KD.singletons.socialapi.message

    fn = if @state then unlike else like
    fn {id}, @bound 'toggleState'


  toggleState: (err) ->

    return @showError err  if err

    @state = not @state

    @setTemplate @pistachio()

    if @getData().interactions.like.isInteracted
    then @trackLike()
    else @trackUnlike()


  trackLike: ->

    KD.mixpanel "Activity like, success"

    KD.getSingleton("badgeController").checkBadge
      source : "JNewStatusUpdate" , property : "likes", relType : "like", targetSelf : 1


  trackUnlike: ->

    KD.mixpanel "Activity unlike, success"


  showError: (err) ->

    KD.showError err,
      AccessDenied : "You are not allowed to like activities"
      KodingError  : "Something went wrong"


  pistachio: ->

    {isInteracted} = @getData().interactions.like

    "#{if isInteracted then "Unlike" else "Like"}"
