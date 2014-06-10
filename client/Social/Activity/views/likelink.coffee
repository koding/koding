class ActivityLikeLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "action-link like-link", options.cssClass

    super options, data

    data
      .on 'LikeAdded', @bound 'update'
      .on 'LikeRemoved', @bound 'update'


  click: ->

    {id}           = data = @getData()
    {isInteracted} = data.interactions.like
    {like, unlike} = KD.singletons.socialapi.message

    fn = if isInteracted then unlike else like
    fn {id}, (err) =>

      return @showError err  if err

      @update()


  update: ->

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
