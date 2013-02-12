class MembersMainView extends KDView

  createCommons:->

    @addSubView header = new HeaderViewSection
      type  : "big"
      title : "Members"

    header.setSearchInput()

















class MembersListItemView extends KDListItemView
  constructor:(options,data)->
    options = options ? {}
    options.type = "members"
    super options,data
    memberData = @getData()
    @avatar = new AvatarView
      size:
        width: 60
        height: 60
    , memberData

    defaultState  = if memberData.followee then "Unfollow" else "Follow"

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
        "Follow", (callback)->
          memberData.follow (err, response)=>
            @hideLoader()
            unless err
              @setClass 'following-btn'
              callback? null
        "Unfollow", (callback)->
          memberData.unfollow (err, response)=>
            @hideLoader()
            unless err
              @unsetClass 'following-btn'
              callback? null
      ]
    , memberData

    memberData.locationTags or= []
    if memberData.locationTags.length < 1
      memberData.locationTags[0] = "Earth"

    @location = new LocationView {},memberData

    @profileLink = new ProfileLinkView {}, memberData

  click:(event)->
    $trg = $(event.target)
    more = "span.collapsedtext a.more-link"
    less = "span.collapsedtext a.less-link"
    $trg.parent().addClass("show").removeClass("hide") if $trg.is(more)
    $trg.parent().removeClass("show").addClass("hide") if $trg.is(less)
    member = @getData()
    targetATag = $(event.target).closest('a')
    if targetATag.is(".followers") and targetATag.find('.data').text() isnt '0'
      KD.getSingleton("appManager").tell "Members", "createFollowsContentDisplay", member, 'followers'
    else if targetATag.is(".following") and targetATag.find('.data').text() isnt '0'
      KD.getSingleton("appManager").tell "Members", "createFollowsContentDisplay", @getData(), 'following'


  clickOnMyItem:(event)->
    if $(event.target).is ".propagateProfile"
      @emit "VisitorProfileWantsToBeShown", {content : @getData(), contentType : "member"}

  isMyItem:()->
    @followButton.destroy() if @followButton?

  viewAppended:->
    @setClass "member-item"
    @setTemplate @pistachio()
    @template.update()
    {profile} = @getData()
    #{currentDelegate} = @getSingleton('mainController').getVisitor()

    @isMyItem() if profile.nickname is KD.whoami().profile.nickname

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
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
      cssClass : 'member-followers content-page-members'
    ,options

    super options, data

  createCommons:(account)->
    headerTitle = "Activities which #{account.profile.firstName} #{account.profile.lastName} liked"
    @addSubView header = new HeaderViewSection type : "big", title : headerTitle
    @listenWindowResize()

    @addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"

    contentDisplayController = @getSingleton "contentDisplayController"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : ()=>
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", @

class MembersContentDisplayView extends KDView
  constructor:(options={}, data)->
    options = $.extend
      view : mainView = new KDView
      cssClass : 'member-followers content-page-members'
    ,options

    super options, data

  createCommons:(account, filter)->
    headerTitle = if filter is "following" then "Members who #{account.profile.firstName} #{account.profile.lastName} follows" else "Members who follow #{account.profile.firstName} #{account.profile.lastName}"
    @addSubView header = new HeaderViewSection type : "big", title : headerTitle
    @listenWindowResize()

    @addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView tagName : "a", partial : "<span>&laquo;</span> Back"

    contentDisplayController = @getSingleton "contentDisplayController"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : backLink
      callback : ()=>
        contentDisplayController.emit "ContentDisplayWantsToBeHidden", @


class MemberFollowToggleButton extends KDToggleButton

  decorateState:(name)->

    @setClass 'following-btn' if name is 'Unfollow'
    super
