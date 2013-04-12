class GroupsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "groups"

    super options,data

    group = @getData()

    {title, slug, body} = group

    @titleLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : "/#{slug}"
        target    : slug
      pistachio   : '{{ #(title)}}'
      # click       : (event) => @titleReceivedClick event
    , group

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
        title         : "Join"
        callback      : (callback)->
          group.join (err, response)=>
            @hideLoader()
            unless err
              # @setClass 'following-btn following-topic'
              @setClass 'following-topic'
              @emit 'Joined'
              callback? null
      ,
        title         : "Leave"
        callback      : (callback)->
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

    @memberCount = new CustomLinkView
      title       : "#{group.counts?.members or 'No'} Members"
      icon        :
        cssClass  : "members"
        placement : "left"

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
      {h3{> @titleLink}}
      <p>
        {{> @memberCount}}
      </p>
      {article{ #(body)}}
    </div>
    <div class='members-list-wrapper hidden'>
      {{> @members}}
    </div>
    <div class='side-wrapper'>
      <div class='badge-wrapper clearfix'>
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
        width   : 40
        height  : 40
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
