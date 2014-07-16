class MembersListItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type        = "member"
    options.avatar     ?=
      size              :
        width           : 30
        height          : 30

    super options, data

    data = @getData()

    avatarSize = @getOption('avatar').size

    @avatar  = new AvatarView
      size       : width: avatarSize.width, height: avatarSize.height
      cssClass   : "avatarview"
      showStatus : yes
    , data

    @actor = new ProfileLinkView {}, data

    # @followersAndFollowing = new JCustomHTMLView
    #   cssClass  : 'user-numbers'
    #   pistachio : "{{ #(counts.followers)}} followers {{ #(counts.following)}} following"
    # , data

    # unless data.getId() is KD.whoami().getId()
    #   @followButton = new FollowButton
    #     title          : "follow"
    #     icon           : yes
    #     stateOptions   :
    #       unfollow     :
    #         title      : "unfollow"
    #         cssClass   : 'following-account'
    #     dataType       : 'JAccount'
    #   , data

  viewAppended:->
    @addSubView @avatar
    # @addSubView @followButton if @followButton
    @addSubView @actor
    # @addSubView @followersAndFollowing
