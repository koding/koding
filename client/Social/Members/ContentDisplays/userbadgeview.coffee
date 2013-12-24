class UserBadgeView extends KDListItemView
  constructor: (options = {}, data) ->
    super options, data
    {iconURL, description, title} = @getData()

    @badgeIcon   = new KDCustomHTMLView
      tagName    : 'img'
      size       :
        width    : 70
        height   : 70
      attributes :
        src      : iconURL
        title    : description or ''

    @title       = new KDCustomHTMLView
      partial    : title

  viewAppended:->
    @addSubView @badgeIcon
    @addSubView @title

class UserPropertyList extends JView
  constructor:(options = {}, data)->
    options.cssClass = "user-property-list"
    # ONLY ADMINS CAN SEE THAT VIEW
    super options, data
  pistachio:->
    """
     <h3>User Properties <span>(staff only)<span></h3>
     <div class="badge-property">
      <p>Likes count : {span.number{ #(counts.likes)}}</p>
      <p>Topic count : {span.number{ #(counts.topics)}}</p>
      <p>Follower count : {span.number{ #(counts.followers)}}</p>
      <p>Comments count : {span.number{ #(counts.comments)}}</p>
      <p>Following count : {span.number{ #(counts.following)}}</p>
      <p>Invitations count : {span.number{ #(counts.invitations)}}</p>
      <p>Referred User count : {span.number{ #(counts.referredUsers)}}</p>
      <p>Status updates count : {span.number{ #(counts.statusUpdates)}}</p>
      <p>Last Login : {span.number{ #(counts.lastLoginDate)}}</p>
    </div>
    """

