$ = require 'jquery'
requireMembership = require '../util/requireMembership'
showError = require '../util/showError'
whoami = require '../util/whoami'
kd = require 'kd'
KDToggleButton = kd.ToggleButton


module.exports = class FollowButton extends KDToggleButton

  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry "follow-btn", options.cssClass
    options = $.extend
      defaultState : if data.followee then "Following" else "Follow"
      bind         : 'mouseenter mouseleave'
      dataPath     : "followee"
      loader       :
        color      : "#333333"
      states       : [
        title      : "Follow"
        cssClass   : options.stateOptions?.follow?.cssClass
        callback   : (cb)=>
          requireMembership
            tryAgain  : yes
            onFailMsg : "Login required to follow"
            onFail    : => cb yes
            callback  : =>
              account = @getData()
              account.follow (err, response) ->
                account.followee = response
                cb? err
      ,
        title      : "Following"
        cssClass   : options.stateOptions?.unfollow?.cssClass
        callback   : (cb)=>
          @getData().unfollow (err, response)=>
            showError err, options.errorMessages
            @getData().followee = response
            cb? err
      ]

    , options

    super options, data

  viewAppended:->
    super

    unless @getData().followee
      {dataType} = @getOptions()
      return  unless dataType

      whoami().isFollowing? @getData().getId(), dataType, \
      (err, following) =>
        @getData().followee = following
        @setState "Following", no  if following

  mouseEnter:->
    if @getTitle() is "Following"
      @setTitle "Unfollow"

  mouseLeave:->
    if @getTitle() is "Unfollow"
      @setTitle "Following"



