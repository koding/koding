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

class UserPropertyList extends KDListView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.type = "user-properties"
    # ONLY ADMINS CAN SEE THAT VIEW
    super options, data

  pistachio:->
    """
     <h3>User Properties <span>(staff only)<span></h3>
     <div class="badge-property">
      <p>Likes count : {span.number{ #(counts.likes) || 0 }}</p>
      <p>Topic count : {span.number{ #(counts.topics) || 0 }}</p>
      <p>Follower count : {span.number{ #(counts.followers) || 0 }}</p>
      <p>Comments count : {span.number{ #(counts.comments) || 0 }}</p>
      <p>Following count : {span.number{ #(counts.following) || 0 }}</p>
      <p>Invitations count : {span.number{ #(counts.invitations) || 0 }}</p>
      <p>Staff Likes count : {span.number{ #(counts.staffLikes) || 0 }}</p>
      <p>Referred User count : {span.number{ #(counts.referredUsers) || 0 }}</p>
      <p>Status updates count : {span.number{ #(counts.statusUpdates) || 0 }}</p>
      <p>Last Login : {span.number{ #(counts.lastLoginDate) || 0 }}</p>
    </div>
    """

