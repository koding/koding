class MembersMainView extends KDView
  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Members"
    header.setSearchInput()

    # @addSubView new CommonFeedMessage
    #   title           : "<p>Here you'll find a list of members of the Koding community. We haven't quite finished our search functionality yet, but it will be available soon.</p>"
    #   messageLocation : 'Members'
    # @listenWindowResize()

class MembersInnerNavigation extends CommonInnerNavigation
  viewAppended:()->
    filterController = @setListController itemClass : MembersListGroupFilterItem,@filterMenuData
    @addSubView filterListWrapper = filterController.getView()

    filterItemToBeSelected = filterController.getItemsOrdered()[0]
    filterController.selectItem filterItemToBeSelected
    @propagateEvent (KDEventType : 'MembersFilter'), filterItemToBeSelected.getData()

    filterController.getListView().registerListener KDEventTypes : 'MembersFilter', listener : @, callback : (pubInst, data)=>
      @propagateEvent KDEventType : 'MembersFilter', data

    sortController = @setListController {},@sortMenuData, yes
    @addSubView sortListWrapper = sortController.getView()
    sortItemToBeSelected = sortController.getItemsOrdered()[0]
    sortController.selectItem sortItemToBeSelected
    @propagateEvent (KDEventType : 'MembersSort'), sortItemToBeSelected.getData()

    # @addSubView helpBox = new HelpBox

class MembersListGroupFilterItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview #{cssClass}'></li>"

  click: (event) =>
    event.stopPropagation()
    event.preventDefault()
    @getDelegate().propagateEvent (KDEventType : 'MembersFilter'), @getData()

  partial:()->
    data = @getData()
    @setClass data.type
    partial = $ "<a href='#'>#{data.title}</a>"

class MembersListGroupSortItem extends KDListItemView
  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview #{cssClass}'></li>"

  click: (event) =>
    event.stopPropagation()
    event.preventDefault()
    @getDelegate().propagateEvent (KDEventType : 'MembersSort'), @getData()

  partial:()->
    data = @getData()
    @setClass data.type
    data.title

# class MembersPaneController extends KDViewController
#   loadView:(mainView)->
#     super
#
#     searchArea = new MembersSearchView
#       cssClass  : "search-area"
#
#     mainView.addSubView container = new KDView
#     container.addSubView searchArea
#
#     container.addSubView membersList = new KDListView {cssClass : "kdlistview kdlistview-members"}
#     new MembersListViewController view : membersList, query : {}, page : {}
#     # membersList.setScroller scrollView : mainView.getDelegate(), fractionBelowTrigger : 1
#     searchArea.setDelegate membersList
#     # searchArea.search()

















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
      appManager.tell "Members", "createFollowsContentDisplay", member, 'followers'
    else if targetATag.is(".following") and targetATag.find('.data').text() isnt '0'
      appManager.tell "Members", "createFollowsContentDisplay", @getData(), 'following'


  clickOnMyItem:(event)->
    if $(event.target).is ".propagateProfile"
      @handleEvent (type : "VisitorProfileWantsToBeShown", content : @getData(), contentType : "member")

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
