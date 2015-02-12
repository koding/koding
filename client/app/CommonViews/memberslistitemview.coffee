class MembersListItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type        = "member"
    options.avatar     ?=
      size              :
        width           : 40
        height          : 40

    super options, data

    data = @getData()

    avatarSize = @getOption('avatar').size

    @avatar  = new AvatarView
      size       : width: avatarSize.width, height: avatarSize.height
      cssClass   : "avatarview"
    , data

    @actor = new ProfileLinkView {}, data

    @followersAndFollowing = new JCustomHTMLView
      cssClass  : 'user-numbers'
      pistachio : "{{ #(counts.followers)}} followers {{ #(counts.following)}} following"
    , data

    unless data.getId() is KD.whoami().getId()
      @followButton = new FollowButton
        title          : "follow"
        icon           : yes
        style          : 'solid green medium'
        stateOptions   :
          unfollow     :
            title      : "unfollow"
            cssClass   : 'following-account'
            style      : 'solid gray medium'
        dataType       : 'JAccount'
      , data

  viewAppended:->
    @addSubView @avatar
    @addSubView @followButton if @followButton
    @addSubView @actor
    @addSubView @followersAndFollowing
