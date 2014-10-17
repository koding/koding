class ActivityLikeLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass   = KD.utils.curry "action-link like-link", options.cssClass
    options.attributes =
      testpath         : 'activity-like-link'

    super options, data

    { @isInteracted } = data.interactions.like

    data
      .on 'LikeAdded',   @bound 'update'
      .on 'LikeRemoved', @bound 'update'
      .on 'LikeChanged', @bound 'setLikeState'


  setLikeState: (state) ->
    @isInteracted = state

    @setTemplate @pistachio()


  click: (event) ->

    KD.utils.stopDOMEvent event

    return  if @locked
    @locked = yes

    {id}           = data = @getData()
    {isInteracted} = data.interactions.like
    {like, unlike} = KD.singletons.socialapi.message

    data.emit 'LikeChanged', not isInteracted

    fn = if isInteracted
    then unlike
    else like

    fn {id}, (err) =>
      @locked = no
      @showError err  if err


  update: ->

    { @isInteracted } = @getData().interactions.like

    @setTemplate @pistachio()

    if @isInteracted
      @trackLike()
      @setClass 'liked'
    else
      @trackUnlike()
      @unsetClass 'liked'


  trackLike: ->

    KD.mixpanel "Activity like, success"


  trackUnlike: ->

    KD.mixpanel "Activity unlike, success"


  showError: (err) ->

    KD.showError err,
      AccessDenied : "You are not allowed to like activities"
      KodingError  : "Something went wrong"


  pistachio: ->

    "#{if @isInteracted then "Unlike" else "Like"}"


