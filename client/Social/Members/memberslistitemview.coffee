class MembersListItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type        = "member"
    super options, data

    data = @getData()

    @avatar  = new AvatarView
      size       : width: 30, height: 30
      cssClass   : "avatarview"
      showStatus : yes
    , data

    @actor = new ProfileLinkView {}, data

    @followersAndFollowing = new KDCustomHTMLView
      cssClass  : 'user-numbers'
      pistachio : "{{ #(counts.followers)}} followers {{ #(counts.following)}} following"
    , data

    unless data.getId() is KD.whoami().getId()
      @followButton = new FollowButton
        title          : "follow"
        icon           : yes
        stateOptions   :
          unfollow     :
            title      : "unfollow"
            cssClass   : 'following-account'
        dataType       : 'JAccount'
      , data

  viewAppended:->
    @addSubView @avatar
    @addSubView @followButton  if @followButton
    @addSubView @actor
    @addSubView @followersAndFollowing
