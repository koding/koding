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


  viewAppended: JView::viewAppended


  pistachio:->

    """
    {span.ttag{ #(title)}}
    {span.tag-info{ #(counts.followers) + ' Followers'}}
    {{> @followButton}}
    """
