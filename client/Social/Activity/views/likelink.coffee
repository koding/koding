class ActivityLikeLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "action-link like-link", options.cssClass

    super options, data

    data
      .on 'LikeAdded', @bound 'update'
      .on 'LikeRemoved', @bound 'update'


  click: (event) ->

    KD.utils.stopDOMEvent event

    return  if @locked
    @locked = yes

    {id}           = data = @getData()
    {isInteracted} = data.interactions.like
    {like, unlike} = KD.singletons.socialapi.message

    fn = if isInteracted then unlike else like
    fn {id}, (err) =>
      @locked = no
      @showError err  if err


  update: ->

    @setTemplate @pistachio()

    if @getData().interactions.like.isInteracted
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

    {isInteracted} = @getData().interactions.like

    "#{if isInteracted then "Unlike" else "Like"}"
