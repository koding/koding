# FIXME : render runs on every data change in account object which leads to a flash on avatarview. Sinan 08/2012

class AvatarView extends LinkView

  constructor:(options = {},data)->

    options.cssClass or= ""
    options.size     or=
      width            : 50
      height           : 50
    options.noTooltip ?= no

    # this needs to be pre-super
    unless options.noTooltip
      @avatarPreview =
        constructorName : AvatarTooltipView
        options :
          delegate : @
          origin : options.origin
        data : data
      # @avatarPreview = new AvatarTooltipView
      #   delegate : @
      #   origin : options.origin
      # ,data

    options.tooltip  or=
      view             : unless options.noTooltip then @avatarPreview else null
      viewCssClass     : 'avatar-tooltip'
      placement         :['top','bottom','right','left'][Math.floor(Math.random()*4)]
      direction         :['left','right','center','top','bottom'][Math.floor(Math.random()*5)]
    options.cssClass = "avatarview #{options.cssClass}"

    super options,data

    # this needs to be post-super
    if @avatarPreview?
      @on 'TooltipReady', =>
        @tooltip.getView()?.updateData @getData() if @getData()?.profile.nickname?

    @bgImg = null

  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    @hideTooltip()
    account = @getData()
    @utils.wait =>
      KD.getSingleton('router').handleRoute "/#{account.profile.nickname}", state:account
    return no

  render:->

    account = @getData()
    return unless account
    {profile} = account
    options = @getOptions()
    fallbackUri = "#{KD.apiUri}/images/defaultavatar/default.avatar.#{options.size.width}.png"
    # @$().attr "title", options.title or "#{Encoder.htmlDecode profile.firstName}'s avatar"

    # this is a temp fix to avoid avatar flashing on every account change - Sinan 08/2012
    bgImg = "url(//gravatar.com/avatar/#{profile.hash}?size=#{options.size.width}&d=#{encodeURIComponent fallbackUri})"

    if @bgImg isnt bgImg
      @$().css "background-image", bgImg
      @bgImg = bgImg

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

    @profileName = new KDCustomHTMLView
      cssClass : 'profile-name'
      click:(event)=>
        KD.getSingleton('router').handleRoute "/#{@getData().profile.nickname}", state:@getData()
      pistachio : \
      """
        <h2>
        {{#(profile.firstName)+' '+#(profile.lastName)}}
        </h2>
      """
    , data

    @staticAvatar = new AvatarStaticView
      cssClass  : 'avatar-static'
      noTooltip : yes
      size      :
        width   : 80
        height  : 80
      origin    : origin
    , data

    defaultState  = "Follow"

    @followButton = new MemberFollowToggleButton
      style           : "follow-btn"
      title           : "Follow"
      dataPath        : "followee"
      defaultState    : defaultState
      loader          :
        color         : "#333333"
        diameter      : 18
        top           : 11
      states          : [
        "Follow", (callback)=>
          @followButton.getData().follow (err, response)=>
            @followButton.hideLoader()
            unless err
              @followButton.setClass 'following-btn'
              callback? null
            else
              log err
        "Unfollow", (callback)=>
          @getData()?.unfollow (err, response)=>
            @followButton.hideLoader()
            unless err
              @followButton.unsetClass 'following-btn'
              callback? null
            else
              log err
      ]
    , @getData()

    @followers = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.followers)}} <span>Followers</span>"
      click       : (event)->
        return if @getData().counts.followers is 0
        appManager.tell "Members", "createFolloweeContentDisplay", @getData(), 'followers'
    , @getData()

    @following = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.following)}} <span>Following</span>"
      click       : (event)->
        return if @getData().counts.following is 0
        appManager.tell "Members", "createFolloweeContentDisplay", @getData(), 'following'
    , @getData()

    @likes = new KDView
      tagName     : 'a'
      attributes  :
        href      : '#'
      pistachio   : "<cite/>{{#(counts.likes) or 0}} <span>Likes</span>"
      click       : (event)->
        return if @getData().counts.following is 0
        appManager.tell "Members", "createLikedContentDisplay", @getData()
    , @getData()

    @sendMessageLink = new MemberMailLink {}, @getData()

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  click:(event)->
    @getDelegate()?.hideTooltip()

  decorateFollowButton:(data)->

    # no dummy data!
    return unless data.getId?

    unless data.followee?
      KD.whoami().isFollowing? data.getId(), "JAccount", (following) =>
        data.followee = following
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