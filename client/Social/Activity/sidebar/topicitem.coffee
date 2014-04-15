class SidebarTopicItem extends SidebarItem

  constructor: (options = {}, data) ->

    options.type = 'sidebar-item'

    super options, data

    @followButton = new FollowButton
      title          : 'follow'
      icon           : yes
      stateOptions   :
        unfollow     :
          title      : 'unfollow'
          cssClass   : 'following-topic'

      dataType       : 'JTag'
    , data

    # fix this, setState instead of hide! - sy
    # and fix toggle button
    @followButton.hide()  if @getData().isParticipant


  viewAppended: JView::viewAppended


  pistachio:->

    {participantCount} = @getData()

    # str = if participantCount > 1 then 'Followers' else 'Follower'

    """
    {span.ttag{ #(name)}}
    {span.tag-info{ #(participantCount) + ' Followers'}}
    {{> @followButton}}
    """
