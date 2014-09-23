class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    {name, participantCount} = data
    options.route            = "Topic/#{name}"
    options.cssClass         = 'clearfix'

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
