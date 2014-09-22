class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    {name, typeConstant, participantCount}    = data

    # rewrite grop channel as topic?
    typeConstant            = "topic" if typeConstant is "group"
    # uppercase first letter of the type constant for route
    typeConstant            = "#{typeConstant.charAt(0).toUpperCase()}#{typeConstant.slice 1}"
    # build route with typeConstant and name
    options.route           = "#{typeConstant}/#{name}"
    options.cssClass        = 'clearfix'

    super options, data

    @followButton = if name is 'public'
    then new KDCustomHTMLView tagName : 'span'
    else new TopicFollowButton {}, @getData()


  pistachio: ->

    """
    {span.ttag{ '#' + #(name)}}
    {span.hidden.participant-count{#(participantCount) + ' followers'}}
    {{> @followButton}}
    {{> @unreadCount}}
    """
