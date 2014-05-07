class SidebarTopicItem extends SidebarItem

  constructor: (options = {}, data) ->

    options.type = 'sidebar-item'

    super options, data

    @followButton = new TopicFollowButton {}, data

  viewAppended: JView::viewAppended


  pistachio:->

    {participantCount} = @getData()

    # str = if participantCount > 1 then 'Followers' else 'Follower'

    """
    {span.ttag{ #(name)}}
    {span.tag-info{ #(participantCount) + ' followers'}}
    {{> @followButton}}
    """
