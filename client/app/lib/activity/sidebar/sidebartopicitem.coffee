kd                  = require 'kd'
KDCustomHTMLView    = kd.CustomHTMLView
JView               = require '../../jview'
SidebarItem         = require './sidebaritem'
TopicFollowButton   = require '../../commonviews/topicfollowbutton'


module.exports = class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  @TYPECONSTANT_GROUP =
    CustomView   : ['group', 'announcement']
    FollowButton : ['topic']

  constructor: (options = {}, data) ->

    {name, typeConstant, participantCount} = data

    # rewrite group channel as topic?
    route            = if typeConstant is 'group' then 'topic' else typeConstant
    route            = route.capitalize()
    options.route    = "#{route}/#{name}"
    options.cssClass = 'clearfix'

    super options, data

    @followButton = switch
      when typeConstant in SidebarTopicItem.TYPECONSTANT_GROUP.CustomView
        new KDCustomHTMLView tagName : 'span'
      else
        new TopicFollowButton {}, @getData()


  setFollowingState : (followingState) ->

    { typeConstant } = @data
    return  unless typeConstant in SidebarTopicItem.TYPECONSTANT_GROUP.FollowButton

    @followButton.setFollowingState followingState


  # this is a fix that we did to not keeping
  # a state of the latest visited /Public route
  # since all the previous routes are kept in router.
  click: (event) ->

    {typeConstant} = @getData()

    {router} = kd.singletons
    {currentPath, visitedRoutes} = router

    if typeConstant is 'group'

      @setUnreadCount 0

      # if the public channel is visited before
      # find the exact route that last visited
      # and navigate to there
      for route in visitedRoutes by -1 when route.search('/Public') isnt -1
        kd.utils.stopDOMEvent event
        router.handleRoute route
        return no

      # if public channel is being visited
      # for the first time navigate to /Public/Liked
      kd.utils.stopDOMEvent event
      router.handleRoute '/Activity/Public/Liked'
      return no

    # if it is some other route
    # just do what href says, thus the default behavior - SY, CtF
    return yes


  pistachio: ->

    """
    {span.ttag{#(name)}}
    {{> @followButton}}
    {{> @unreadCount}}
    """


