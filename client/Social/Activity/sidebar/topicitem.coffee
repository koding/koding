class SidebarTopicItem extends SidebarItem

  JView.mixin @prototype

  getSuffix = (c)-> str : if c > 1 then ' Followers' else ' Follower'

  constructor: (options = {}, data) ->

    options.type            = 'sidebar-item'
    options.pistachioParams = getSuffix data.participantCount

    super options, data

    data = @getData()

    @followButton = new TopicFollowButton {}, data


  render: ->

    @setOption 'pistachioParams', getSuffix @getData().participantCount

    super


  pistachio: ->

    """
    {span.ttag{ #(name)}}
    {span.tag-info{ #(participantCount) + str}}
    {{> @followButton}}
    """
