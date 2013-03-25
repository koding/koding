class GroupsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "groups"

    super options,data

    group = @getData()

    {title, slug, body} = group
    @backgroundImage = "../images/defaultavatar/default.group.128.png"
    @avatar = new KDCustomHTMLView
      tagName : 'img'
      cssClass : 'avatar-image'
      attributes :
        # src : group.avatar or "/images/defaultavatar/default.group.128.png"
        src : group.avatar or @backgroundImage

    # @settingsButton = new KDButtonViewWithMenu
    #     cssClass    : 'transparent groups-settings-context groups-settings-menu'
    #     title       : ''
    #     icon        : yes
    #     delegate    : @
    #     iconClass   : "arrow"
    #     menu        : @settingsMenu group
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
    , group

    # @bodyView = new KDCustomHTMLView
    #   tagName     : 'div'
    #   partial     : group.body
    #   tooltip     :
    #     title     : body
    #     direction : 'right'
    #     placement : 'top'
    #     offset    :
    #       top     : 6
    #       left    : -2
    #     showOnlyWhenOverflowing : yes
    # ,group

    @joinButton = new JoinButton
      style           : if group.member then "join-group follow-btn following-topic" else "join-group follow-btn"
      title           : "Join"
      dataPath        : "member"
      defaultState    : if group.member then "Leave" else "Join"
      loader          :
        color         : "#333333"
        diameter      : 18
        top           : 11
      states          : [
        "Join", (callback)->
          group.join (err, response)=>
            @hideLoader()
            unless err
              # @setClass 'following-btn following-topic'
              @setClass 'following-topic'
              @emit 'Joined'
              callback? null
        "Leave", (callback)->
          group.leave (err, response)=>
            @hideLoader()
            unless err
              # @unsetClass 'following-btn following-topic'
              @unsetClass 'following-topic'
              @emit 'Left'
              callback? null
      ]
    , group

    @joinButton.on 'Joined', =>
      @enterButton.show()

    @joinButton.on 'Left', =>
      @enterButton.hide()

    @enterLink = new CustomLinkView
      href    : "/#{slug}/Activity"
      target  : slug
      title   : 'Open group'
      click   : @bound 'privateGroupOpenHandler'

    membersController = new KDListViewController
      view         : @members = new KDListView
        wrapper    : no
        scrollView : no
        type       : "members"
        itemClass  : GroupItemMemberView

    # FIXME: SY
    # instantiateListItems doesnt fire by default
    unless group.slug is "koding"
      group.fetchMembers (err, members)=>
        if err then warn err
        else if members
          @$('.members-list-wrapper').removeClass "hidden"
          membersController.instantiateListItems members

    @memberBadge = new KDCustomHTMLView
      tagName   : "div"
      cssClass  : "badge member"
      partial   : "<span class='fold'/>You are a member"

    @privateBadge = new KDCustomHTMLView
      tagName   : "div"
      cssClass  : "badge private #{if group.privacy is 'private' then '' else 'hidden'}"
      partial   : "<span class='fold'/><span class='icon'/>"

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
      <div class='members-list-wrapper hidden'>
        <cite>MEMBERS</cite>
        {{> @members}}
      </div>
      <div class='badge-wrapper'>
        {{> @memberBadge}}
        {{> @privateBadge}}
      </div>
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

    account = @getData()
    {firstName, lastName} = account.profile
    @avatar = new AvatarView
      size      :
        width   : 30
        height  : 30
      # detailed  : yes
      tooltip   :
        title   : "#{firstName} #{lastName}"
    , account

  viewAppended:JView::viewAppended

  pistachio:-> "{{> @avatar}}"

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
