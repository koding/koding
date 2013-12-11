class UserBadgeView extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data
    {iconURL, description} = @getData()
    @badgeIcon   = new KDCustomHTMLView
      tagName    : 'img'
      size       :
        width    : 70
        height   : 70
      attributes :
        src      : iconURL
        title    : description or ''

  viewAppended:->
    @addSubView @badgeIcon

class UserPropertyList extends JView
  constructor:(options = {}, data)->
    # ONLY ADMINS CAN SEE THAT VIEW
    super options, data
  pistachio:->
    {counts} = @getData()
    """
     <a href="#">User Properties</a>
     <div class="badge-property">
      <p>Follower count : <span class='number'>#{counts.followers}</span></p>
      <p>Following count : <span class='number'>#{counts.following}</span></p>
      <p>Comments count : <span class='number'>#{counts.comments}</span></p>
      <p>Invitations count : <span class='number'>#{counts.invitations}</span></p>
      <p>Last Login Date: <span class='number'>#{counts.lastLoginDate}</span></p>
      <p>Likes count : <span class='number'>#{counts.likes}</span></p>
      <p>Referred User count : <span class='number'>#{counts.referredUsers}</span></p>
      <p>Status updates count : <span class='number'>#{counts.statusUpdates}</span></p>
      <p>Topics count : <span class='number'>#{counts.topics}</span></p>
    </div>
    """

