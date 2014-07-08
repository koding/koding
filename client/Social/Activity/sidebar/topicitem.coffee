class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    {name}                  = data
    options.route           = "Topic/#{name}"
    options.cssClass        = 'clearfix'

    super options, data

    @followButton = new TopicFollowButton {}, @getData()


  pistachio: ->

    """
    {span.ttag{ '#' + #(name)}}
    {{> @followButton}}
    {{> @unreadCount}}
    """
