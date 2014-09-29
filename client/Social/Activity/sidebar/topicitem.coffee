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


  pistachio: ->

    """
    {span.ttag{ '#' + #(name)}}
    {{> @followButton}}
    {{> @unreadCount}}
    """
