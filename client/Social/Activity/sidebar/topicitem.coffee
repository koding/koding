class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  getSuffix = (c)-> str : if c > 1 then ' Followers' else ' Follower'

  constructor: (options = {}, data) ->

    {name}                  = data
    options.pistachioParams = getSuffix data.participantCount
    options.route           = "Topic/#{name}"
    options.cssClass        = 'clearfix'

    super options, data

    @followButton = new TopicFollowButton {}, @getData()


  render: ->

    @setOption 'pistachioParams', getSuffix @getData().participantCount

    super


  pistachio: ->

    """
    {span.ttag{ '#' + #(name)}}
    {span.tag-info{ #(participantCount) + str}}
    {{> @followButton}}
    {{> @unreadCount}}
    """
