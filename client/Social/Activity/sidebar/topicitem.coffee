class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    {name, typeConstant, participantCount} = data

    # rewrite group channel as topic?
    route            = if typeConstant is 'group' then 'topic' else typeConstant
    route            = route.capitalize()
    options.route    = "#{route}/#{name}"
    options.cssClass = 'clearfix'

    super options, data

    @followButton = if typeConstant in ['group', 'announcement']
    then new KDCustomHTMLView tagName : 'span'
    else new TopicFollowButton {}, @getData()

  # this is a fix that we did to not keeping
  # a state of the latest visited /Public route
  # since all the previous routes are kept in router.
  click: (event) ->

    {typeConstant} = @getData()

    {router} = KD.singletons
    {currentPath, visitedRoutes} = router

    if typeConstant is 'group'

      # if the public channel is visited before
      # find the exact route that last visited
      # and navigate to there
      for route in visitedRoutes by -1 when route.search('/Public') isnt -1
        KD.utils.stopDOMEvent event
        router.handleRoute route
        return no

      # if public channel is being visited
      # for the first time navigate to /Public/Liked
      KD.utils.stopDOMEvent event
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
