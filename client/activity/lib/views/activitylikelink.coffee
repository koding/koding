kd = require 'kd'
showError = require 'app/util/showError'
CustomLinkView = require 'app/customlinkview'


module.exports = class ActivityLikeLink extends CustomLinkView

  {warn} = kd

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry "action-link like-link", options.cssClass
    options.attributes =
      testpath         : 'activity-like-link'

    super options, data

    @update()

    data
      .on 'LikeAdded',   @bound 'update'
      .on 'LikeRemoved', @bound 'update'
      .on 'LikeChanged', @bound 'setLikeState'


  setLikeState: (state) ->
    { like } = @getData().interactions
    like.isInteracted = state
    @update()


  click: (event) ->

    kd.utils.stopDOMEvent event

    return  if @locked
    @locked = yes

    {id}           = data = @getData()
    {isInteracted} = data.interactions.like
    {like, unlike} = kd.singletons.socialapi.message

    data.emit 'LikeChanged', not isInteracted

    fn = if isInteracted
    then unlike
    else like

    fn {id}, (err) =>
      @locked = no
      if err
        data.emit 'LikeChanged', isInteracted
        warn err


  update: ->

    { isInteracted } = @getData().interactions.like

    @setTemplate @pistachio()

    if isInteracted
    then @setClass 'liked'
    else @unsetClass 'liked'


  showError: (err) ->

    showError err,
      AccessDenied : "You are not allowed to like activities"
      KodingError  : "Something went wrong"


  pistachio: ->

    { isInteracted } = @getData().interactions.like
    "#{if isInteracted then "Unlike" else "Like"}"
