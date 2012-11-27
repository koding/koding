class FollowButton extends KDToggleButton
  
  constructor:(options, data)->
    options.cssClass = @utils.curryCssClass "follow-btn", options.cssClass
    options.title           or= "Follow"
    options.dataPath        or= "followee"
    options.defaultState    or= "Follow"
    options.loader          or=
      color                 : "#333333"
      diameter              : 18
      top                   : 11
    options.states          or= [
      "Follow",     @createStateCallback "follow"
      "Following",  @createStateCallback "unfollow"
    ]
    super

  createStateCallback:(method)->
    (callback)->
      @getData()[method] (err, response)=>
        unless err
          callback? null
          @redecorateState()

  decorateState:(name)->

  redecorateState:->
    @setTitle @state
    method = if @state is 'Follow' then 'unsetClass' else 'setClass'
    @[method] "following-btn"
    @hideLoader()