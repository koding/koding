class AvatarTooltipView extends JView
  constructor:(options={}, data)->

    super options, data

    origin = options.origin
    name   = KD.utils.getFullnameFromAccount @getData()

    @profileName = new JView
      tagName    : 'a'
      cssClass   : 'profile-name'
      attributes :
        href     : "/#{@getData().profile.nickname}"
        target   : '_blank'
      pistachio  : "<h2>#{name}</h2>"
    , data

    @staticAvatar = new AvatarStaticView
      cssClass  : 'avatar-static'
      noTooltip : yes
      size      :
        width   : 80
        height  : 80
      origin    : origin
    , data


    @followButton = new MemberFollowToggleButton
      style       : "follow-btn"
      loader      :
        color     : "#333333"
        diameter  : 18
        top       : 11
    , @getData()

    @followers = new JView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        return if @getData().counts.followers is 0
        KD.getSingleton("appManager").tell "Members", "createFolloweeContentDisplay", @getData(), 'followers'
    , @getData()

    @following = new JView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if @getData().counts.following is 0
        KD.getSingleton("appManager").tell "Members", "createFolloweeContentDisplay", @getData(), 'following'
    , @getData()

    @likes = new JView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)=>
        return if @getData().counts.following is 0
        KD.getSingleton("appManager").tell "Members", "createLikedContentDisplay", @getData()
    , @getData()

    @sendMessageLink = new MemberMailLink {}, @getData()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  click:(event)->
    # @getDelegate()?.getTooltip().hide()

  decorateFollowButton:(data)->

    # no dummy data!
    return unless data.getId?

    unless data.followee?
      KD.whoami().isFollowing? data.getId(), "JAccount", (err, following)=>
        data.followee = following
        warn err  if KD.isLoggedIn()
        if data.followee
          @followButton.setClass 'following-btn'
          @followButton.setState "Following"
        else
          @followButton.setState "Follow"
          @followButton.unsetClass 'following-btn'
    else
      if data.followee
        @followButton.setClass 'following-btn'
        @followButton.setState "Following"
    @followButton.setData data
    @followButton.render()

  updateData:(data={})->

    # lazy loading data is spoonfed to the individual views
    @setData data

    @decorateFollowButton data

    @profileName.setData data
    @profileName.render()

    @followers.setData data
    @following.setData data
    @likes.setData data
    @sendMessageLink.setData data

    @followers.render()
    @following.render()
    @likes.render()
    @sendMessageLink.render()

  pistachio:->
    """
    <div class="leftcol">
      {{> @staticAvatar}}
      {{> @followButton}}
    </div>
    <div class="rightcol">
      {{> @profileName}}
      <div class="profilestats">
          <div class="fers">
            {{> @followers}}
          </div>
          <div class="fing">
            {{> @following}}
          </div>
           <div class="liks">
            {{> @likes}}
          </div>
          <div class='contact'>
            {{> @sendMessageLink}}
          </div>
        </div>
    </div>
    """
