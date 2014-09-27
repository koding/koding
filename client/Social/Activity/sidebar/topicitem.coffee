class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    {name, typeConstant, participantCount}    = data

    # rewrite grop channel as topic?
    firstRoute              = if typeConstant is "group" then "topic" else typeConstant
    # uppercase first letter of the type constant for route
    firstRoute              = "#{firstRoute.charAt(0).toUpperCase()}#{firstRoute.slice 1}"
    # build route with firstRoute and name
    options.route           = "#{firstRoute}/#{name}"
    options.cssClass        = 'clearfix'

    super options, data

    @followButton = if typeConstant in ['group', 'announcement']
    then new KDCustomHTMLView tagName : 'span'
    else new TopicFollowButton {}, @getData()


  pistachio: ->

    """
    {span.ttag{ '#' + #(name)}}
    {span.hidden.participant-count{#(participantCount) + ' followers'}}
    {{> @followButton}}
    {{> @unreadCount}}
    """
