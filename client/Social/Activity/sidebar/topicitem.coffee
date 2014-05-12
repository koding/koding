class SidebarTopicItem extends SidebarItem

  getSuffix = (c)-> str : if c > 1 then ' Followers' else ' Follower'

  constructor: (options = {}, data) ->

    options.type            = 'sidebar-item'
    options.pistachioParams = getSuffix data.participantCount

    super options, data

    data = @getData()

    @followButton = new TopicFollowButton {}, data


  viewAppended: JView::viewAppended

  render: ->

    @setOption 'pistachioParams', getSuffix @getData().participantCount

    super


  pistachio: ->

    """
    {span.ttag{ #(name)}}
    {span.tag-info{ #(participantCount) + str}}
    {{> @followButton}}
    """
