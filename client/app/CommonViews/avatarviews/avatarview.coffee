class AvatarView extends LinkView

  constructor:(options = {},data)->

    options.cssClass or= ""
    options.size     or=
      width            : 50
      height           : 50
    options.detailed  ?= no

    # this needs to be pre-super
    if options.detailed
      @detailedAvatar   =
        constructorName : AvatarTooltipView
        options         :
          delegate      : @
          origin        : options.origin
        data            : data

      options.tooltip or= {}
      options.tooltip.view         or= if options.detailed then @detailedAvatar else null
      options.tooltip.viewCssClass or= 'avatar-tooltip'
      options.tooltip.animate      or= yes
      options.tooltip.placement    or= 'top'
      options.tooltip.direction    or= 'right'

    options.cssClass = "avatarview #{options.cssClass}"

    super options,data

    if @detailedAvatar?
      @on 'TooltipReady', =>
        @utils.defer =>
          data = @getData()
          @tooltip.getView().updateData data if data?.profile.nickname

    @bgImg = null
    @fallbackUri = "#{KD.apiUri}/images/defaultavatar/default.avatar.#{options.size.width}.png"

  setAvatar:(uri)->
    if @bgImg isnt uri
      @$().css "background-image", uri
      @bgImg = uri

  render:->
    account = @getData()
    return unless account

    {profile, type} = account
    return @setAvatar "url(#{@fallbackUri})"  if type is 'unregistered'

    {width} = @getOptions().size
    @setAvatar "url(//gravatar.com/avatar/#{profile.hash}?size=#{width}&d=#{encodeURIComponent @fallbackUri})"

    flags = account.globalFlags?.join(" ") ? ""
    @$('cite').addClass flags

  viewAppended:->
    super
    @render() if @getData()

  pistachio:-> '<cite></cite>'


class AvatarTooltipView extends KDView
  constructor:(options={}, data)->

    super options, data

    origin = options.origin
    name   = KD.utils.getFullnameFromAccount @getData()

    @profileName = new KDCustomHTMLView
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

    @followers = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        return if @getData().counts.followers is 0
        KD.getSingleton("appManager").tell "Members", "createFolloweeContentDisplay", @getData(), 'followers'
    , @getData()

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if @getData().counts.following is 0
        KD.getSingleton("appManager").tell "Members", "createFolloweeContentDisplay", @getData(), 'following'
    , @getData()

    @likes = new KDView
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
          @followButton.setState "Unfollow"
        else
          @followButton.setState "Follow"
          @followButton.unsetClass 'following-btn'
    else
      if data.followee
        @followButton.setClass 'following-btn'
        @followButton.setState "Unfollow"
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