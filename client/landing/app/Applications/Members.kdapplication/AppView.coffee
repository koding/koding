class MembersMainView extends KDView

  createCommons:->

    @addSubView @header = new HeaderViewSection
      type  : "big"
      title : "Members"

    @getSingleton("mainController").on 'AccountChanged', @bound 'setSearchInput'
    @setSearchInput()

  setSearchInput:->
    @header.setSearchInput()  if 'list members' in KD.config.permissions

class MembersListItemView extends KDListItemView
  constructor:(options, data)->

    options = options ? {}
    options.type = "members"
    options.avatarSizes or= [60, 60] # [width, height]

    super options,data

    memberData = @getData()
    options    = @getOptions()

    @avatar = new AvatarView
      size:
        width: options.avatarSizes[0]
        height: options.avatarSizes[1]
    , memberData

    if memberData.profile.nickname is KD.whoami().profile.nickname
    then @followButton = new KDView
    else @followButton = new MemberFollowToggleButton
      style       : "follow-btn"
      loader      :
        color     : "#333333"
        diameter  : 18
        top       : 11
    , memberData

    memberData.locationTags or= []
    if memberData.locationTags.length < 1
      memberData.locationTags[0] = "Earth"

    @location = new LocationView {},memberData

    @profileLink = new ProfileLinkView {}, memberData

  click:(event)->
    KD.utils.showMoreClickHandler.call this, event
    targetATag = $(event.target).closest('a')
    if targetATag.is(".followers") and targetATag.find('.data').text() isnt '0'
      KD.getSingleton('router').handleRoute "/#{@getData().profile.nickname}/Followers"
    else if targetATag.is(".following") and targetATag.find('.data').text() isnt '0'
      KD.getSingleton('router').handleRoute "/#{@getData().profile.nickname}/Following"

  clickOnMyItem:(event)->
    if $(event.target).is ".propagateProfile"
      @emit "VisitorProfileWantsToBeShown", {content : @getData(), contentType : "member"}

  viewAppended:->
    @setClass "member-item"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <span>
        {{> @avatar}}
      </span>

      <div class='member-details'>
        <header class='personal'>
          <h3>{{> @profileLink}}</h3> <span>{{> @location}}</span>
        </header>

        <p>{{ @utils.applyTextExpansions #(profile.about), yes}}</p>

        <footer>
          <span class='button-container'>{{> @followButton}}</span>
          <a class='followers' href='#'> <cite></cite> {{#(counts.followers)}} Followers</a>
          <a class='following' href='#'> <cite></cite> {{#(counts.following)}} Following</a>
          <time class='timeago hidden'>
            <span class='icon'></span>
            <span>
              Active <cite title='{{#(meta.modifiedAt)}}'></cite>
            </span>
          </time>
        </footer>

      </div>
    """


class MembersLocationView extends KDCustomHTMLView
  constructor: (options, data) ->
    options = $.extend {tagName: 'p', cssClass: 'place'}, options
    super options, data

  viewAppended: ->
    locations = @getData()
    @setPartial locations?[0] or ''

class MembersLikedContentDisplayView extends KDView

  constructor:(options = {}, data)->

    options.view     or= mainView = new KDView
    options.cssClass or= 'member-followers content-page-members'

    super options, data

  createCommons:(account)->
    contentDisplayController = @getSingleton "contentDisplayController"
    headerTitle              = "Activities which #{account.profile.firstName} #{account.profile.lastName} liked"

    @addSubView header = new HeaderViewSection
      type  : "big"
      title : headerTitle

    @addSubView subHeader = new KDCustomHTMLView
      tagName  : "h2"
      cssClass : 'sub-header'

    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : => contentDisplayController.emit "ContentDisplayWantsToBeHidden", @

    @listenWindowResize()



class MembersContentDisplayView extends KDView
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
      cssClass : 'member-followers content-page-members'
    ,options

    super options, data

  createCommons:(account, filter)->
    headerTitle = if filter is "following" then "Members who #{account.profile.firstName} #{account.profile.lastName} follows" else "Members who follow #{account.profile.firstName} #{account.profile.lastName}"
    @addSubView header = new HeaderViewSection
      type  : "big"
      title : headerTitle

    @addSubView subHeader = new KDCustomHTMLView
      tagName  : "h2"
      cssClass : 'sub-header'

    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : (event)=>
        event.preventDefault()
        event.stopPropagation()
        @getSingleton('contentDisplayController').emit "ContentDisplayWantsToBeHidden", @

    @listenWindowResize()


class MemberFollowToggleButton extends KDToggleButton

  constructor:(options = {}, data)->
    options = $.extend
      title           : "Follow"
      dataPath        : "followee"
      defaultState    : "Follow"
      loader          :
        color         : "#333333"
        diameter      : 18
      states          : [
        title         : "Follow"
        callback      : (callback)->
          KD.requireMembership
            callback  : =>
              @getData().follow (err, response)=>
                @hideLoader()
                unless err
                  @getData().followee = yes
                  @setClass 'following-btn'
                  callback? null
            tryAgain  : yes
            onFailMsg : 'Login required to follow members'
            onFail    : => @hideLoader()
      ,
        title         : "Unfollow"
        callback      : (callback)->
          @getData().unfollow (err, response)=>
            @hideLoader()
            unless err
              @getData().followee = no
              @unsetClass 'following-btn'
              callback? null
      ]
    , options

    super options, data

    decorator = (following)=>
      if @getData().followee
        @setClass 'following-btn'
        @setState "Unfollow"
      else
        @setState "Follow"
        @unsetClass 'following-btn'

    if @getData().followee?
      decorator @getData().followee
    else
      KD.whoami().isFollowing? @getData().getId(), "JAccount", \
        (err, following) =>
          @getData().followee = following
          warn err  if err and KD.isLoggedIn()
          decorator following

  decorateState:(name)->

    @setClass 'following-btn' if name is 'Unfollow'
    super
