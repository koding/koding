class ActivityLikeLink extends CustomLinkView

  constructor: (options = {}, data) ->

    @state = data.interactions.like.isInteracted

    super options, data


  click: ->

    {socialapi: {message: {like, unlike}}} = KD.singletons

    fn = if @state then unlike else like
    fn id: @getData().id, @bound "toggleState"


  toggleState: (err) ->

    return @showError err  if err

    @state = not @state

    @setTemplate @pistachio()

    if @state
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

    "#{if @state then "Unlike" else "Like"}"
