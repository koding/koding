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

    @membersController = new KDListViewController
      view         : @members = new KDListView
        wrapper    : no
        scrollView : no
        type       : "members"
        itemClass  : GroupItemMemberView
    @fetchMembers() if group.privacy is 'public'

    @memberBadge = new KDCustomHTMLView
      tagName   : "div"
      cssClass  : "badge member"
      partial   : "You are a member"

    @privateBadge = new KDCustomHTMLView
      tagName   : "div"
      cssClass  : "badge private #{if group.privacy is 'private' then '' else 'hidden'}"
      partial   : "<span class='icon'/>"
      tooltip   :
        title   : "Restricted access"

    @memberCount = new CustomLinkView
      title       : "#{group.counts?.members or 'No'} Members"
      icon        :
        cssClass  : "members"
        placement : "left"

    menu = @settingsMenu data
    if Object.keys(menu).length > 0
      @settingsButton = new KDButtonViewWithMenu
        cssClass    : 'transparent group-settings-context'
        title       : ''
        delegate    : @
        type        : 'contextmenu'
        menu        : menu
        callback    : (event)=> @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView "hidden"

  privateGroupOpenHandler: GroupsAppController.privateGroupOpenHandler

  titleReceivedClick:(event)->
    group = @getData()
    KD.getSingleton('router').handleRoute "/#{group.slug}", state:group
    event.stopPropagation()
    event.preventDefault()
    #KD.getSingleton("appManager").tell "Groups", "createContentDisplay", group

  viewAppended: JView::viewAppended

  setFollowerCount:(count)-> @$('.followers a').html count

  markMemberGroup:->
    @setClass "member-group"
    @fetchMembers() if @getData().privacy isnt 'public'

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
        {{> @settingsButton}}
      </div>
    </div>
    """

  settingsMenu:(data)->

    menu = {}

    if data.slug isnt 'koding'
      menu['Leave Group'] =
        callback : =>
          modal = new KDModalView
            title          : 'Leave Group'
            content        : "<div class='modalformline'>Are you sure you want to leave this group?</div>"
            height         : 'auto'
            overlay        : yes
            buttons        :
              Leave        :
                style      : "modal-clean-red"
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @leaveGroup data, =>
                    @memberBadge.hide()
                    @settingsButton.hide()
                    modal.buttons.Leave.hideLoader()
                    modal.destroy()
              Cancel       :
                style      : "modal-cancel"
                callback   : (event)-> modal.destroy()

      menu['Remove Group'] =
        cssClass : 'remove-group hidden'
        callback : =>
          modal = new GroupsDangerModalView
            action     : 'Remove Group'
            longAction : 'remove this group'
            callback   : (callback)=>
              data.remove (err)=>
                callback()
                if err
                  return new KDNotificationView title: if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
                new KDNotificationView title:'Ok, we removed your group with a heavy heart!'
                modal.destroy()
                @destroy()
          , data

    return menu

  leaveGroup:(group, callback)->

    group.leave (err)->
      if err
        warn err
        new KDNotificationView
          title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
          duration : 2000
        return callback()

      new KDNotificationView
        title    : 'Fair Enough! They are gonna miss you.'
        duration : 2000

      currentGroup = KD.getSingleton('groupsController').getCurrentGroup()
      currentGroupSlug = currentGroup.getAt 'slug'
      if group.slug is currentGroupSlug
        document.location.reload()
      callback()

  fetchMembers:->
    @getData().fetchMembers (err, members)=>
      if err
        # HK: better we have error codes for such things
        warn err unless err.name is 'KodingError' and err.message is 'Access denied'
      else if members
        @$('.members-list-wrapper').removeClass "hidden"
        @membersController.instantiateListItems members

class GroupItemMemberView extends KDListItemView

  constructor:(options = {}, data)->

    options.type    = "member"
    options.tagName = "span"

    super options, data

    account = @getData()
    {firstName, lastName} = account.profile
    @avatar = new AvatarView
      size      :
        width   : @getOptions().childOptions?.avatarWidth or 40
        height  : @getOptions().childOptions?.avatarHeight or 40
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
