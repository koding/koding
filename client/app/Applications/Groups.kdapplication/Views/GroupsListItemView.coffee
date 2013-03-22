class GroupsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "groups"
    super options,data

    {title, slug, body} = @getData()
    @backgroundImage = "../images/defaultavatar/default.group.128.png"
    @avatar = new KDCustomHTMLView
      tagName : 'img'
      cssClass : 'avatar-image'
      attributes :
        # src : @getData().avatar or "/images/defaultavatar/default.group.128.png"
        src : @getData().avatar or @backgroundImage

    # @settingsButton = new KDButtonViewWithMenu
    #     cssClass    : 'transparent groups-settings-context groups-settings-menu'
    #     title       : ''
    #     icon        : yes
    #     delegate    : @
    #     iconClass   : "arrow"
    #     menu        : @settingsMenu data
    #     callback    : (event)=> @settingsButton.contextMenu event

    # TODO : hide settings button for non-admins
    # @settingsButton.hide()


    @titleLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : "/#{slug}"
        target    : slug
      pistachio   : '{{ #(title)}}'
      # click       : (event) => @titleReceivedClick event
    , data

    # @bodyView = new KDCustomHTMLView
    #   tagName     : 'div'
    #   partial     : data.body
    #   tooltip     :
    #     title     : body
    #     direction : 'right'
    #     placement : 'top'
    #     offset    :
    #       top     : 6
    #       left    : -2
    #     showOnlyWhenOverflowing : yes
    # ,data

    @joinButton = new JoinButton
      style           : if data.member then "join-group follow-btn following-topic" else "join-group follow-btn"
      title           : "Join"
      dataPath        : "member"
      defaultState    : if data.member then "Leave" else "Join"
      loader          :
        color         : "#333333"
        diameter      : 18
        top           : 11
      states          : [
        "Join", (callback)->
          data.join (err, response)=>
            @hideLoader()
            unless err
              # @setClass 'following-btn following-topic'
              @setClass 'following-topic'
              @emit 'Joined'
              callback? null
        "Leave", (callback)->
          data.leave (err, response)=>
            @hideLoader()
            unless err
              # @unsetClass 'following-btn following-topic'
              @unsetClass 'following-topic'
              @emit 'Left'
              callback? null
      ]
    , data

    @joinButton.on 'Joined', =>
      @enterButton.show()

    @joinButton.on 'Left', =>
      @enterButton.hide()

    @enterLink = new CustomLinkView
      href    : "/#{slug}/Activity"
      target  : slug
      title   : 'Open group'
      click   : @bound 'privateGroupOpenHandler'

    memberCount = @getData().counts?.members or 0
    memberCount = if memberCount > 19 then 19 else memberCount

    members = ({title: @utils.getDummyName()} for i in [0..memberCount])

    # log members

    membersController = new KDListViewController
      view         : @members = new KDListView
        wrapper    : no
        scrollView : no
        type       : "members"
        itemClass  : GroupItemMemberView
    # ,
    #   items : members

    # FIXME: SY
    # instantiateListItems doesnt fire by default
    @members.on "viewAppended", ->
      membersController.instantiateListItems members

    @ownGroupTitle = new KDCustomHTMLView
      tagName   : "div"
      cssClass  : "own-group-title"
      partial   : "<span/>You are a member"


  privateGroupOpenHandler: GroupsAppController.privateGroupOpenHandler

  titleReceivedClick:(event)->
    group = @getData()
    KD.getSingleton('router').handleRoute "/#{group.slug}", state:group
    event.stopPropagation()
    event.preventDefault()
    #KD.getSingleton("appManager").tell "Groups", "createContentDisplay", group

  viewAppended: JView::viewAppended

  setFollowerCount:(count)-> @$('.followers a').html count

  markOwnGroup:-> @setClass "own-group"

  pistachio:->
    """
    <div class="wrapper">
      <span class="avatar">{{>@avatar}}</span>
      <div class="content right-overflow">
        {h3{> @titleLink}}
        {article{ #(body)}}
      </div>
      <cite>MEMBERS</cite>
      {{> @members}}
      {{> @ownGroupTitle}}
    </div>
    """

  # settingsMenu:(data)->

  #   account        = KD.whoami()
  #   mainController = @getSingleton('mainController')

  #   menu =
  #     'Group settings'  :
  #       callback        : =>
  #         mainController.emit 'EditGroupButtonClicked', @
  #     # 'Permissions'     :
  #     #   callback : =>
  #     #     mainController.emit 'EditPermissionsButtonClicked', @
  #     'My roles'        :
  #       callback        : =>
  #         mainController.emit 'MyRolesRequested', @

  #   # if KD.checkFlag 'super-admin'
  #   #   menu =
  #   #     'MARK USER AS TROLL' :
  #   #       callback : =>
  #   #         mainController.markUserAsTroll data
  #   #     'UNMARK USER AS TROLL' :
  #   #       callback : =>
  #   #         mainController.unmarkUserAsTroll data

  #   return menu

class GroupItemMemberView extends KDListItemView

  constructor:(options = {}, data)->

    options.type    = "member"
    options.tagName = "span"

    super options, data

    @setTooltip
      title : @getData().title
      delay : 300

  partial:->
    """
    <img class="avatar-image" src="../images/defaultavatar/default.avatar.60.png">
    """

class ModalGroupsListItem extends TopicsListItemView

  constructor:(options,data)->

    super options,data

    @titleLink = new TagLinkView
      expandable: no
      click     : => @getDelegate().emit "CloseTopicsModal"
    , data

  pistachio:->
    """
    <div class="topictext">
      <div class="topicmeta">
        <div class="button-container">{{> @joinButton}}</div>
        {{> @titleLink}}
        <div class="stats">
          <p class="members">
            <span class="icon"></span>{{#(counts.members) or 0}} Members
          </p>
        </div>
      </div>
    </div>
    """

class GroupsListItemViewEditable extends GroupsListItemView

  constructor:(options = {}, data)->

    options.editable = yes
    options.type     = "topics"

    super options, data
