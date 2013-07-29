class GroupsListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.type = "groups"

    super options,data

    group = @getData()
    {title, slug, body} = group

    slugLink = if slug is KD.defaultSlug then '/' else "/#{slug}"

    @titleLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : slugLink
        target    : slug
      pistachio   : '{{ #(title)}}'
      # click       : (event) => @titleReceivedClick event
    , group

    # @joinButton = new JoinButton
    #   style           : if group.member then "join-group follow-btn following-topic" else "join-group follow-btn"
    #   title           : "Join"
    #   dataPath        : "member"
    #   defaultState    : if group.member then "Leave" else "Join"
    #   loader          :
    #     color         : "#333333"
    #     diameter      : 18
    #     top           : 11
    #   states          : [
    #     title         : "Join"
    #     callback      : (callback)->
    #       group.join (err, response)=>
    #         @hideLoader()
    #         unless err
    #           # @setClass 'following-btn following-topic'
    #           @setClass 'following-topic'
    #           @emit 'Joined'
    #           callback? null
    #   ,
    #     title         : "Leave"
    #     callback      : (callback)->
    #       group.leave (err, response)=>
    #         @hideLoader()
    #         unless err
    #           # @unsetClass 'following-btn following-topic'
    #           @unsetClass 'following-topic'
    #           @emit 'Left'
    #           callback? null
    #   ]
    # , group

    # @joinButton.on 'Joined', =>
    #   @enterButton.show()

    # @joinButton.on 'Left', =>
    #   @enterButton.hide()

    @enterLink = new CustomLinkView
      href    : "#{slugLink}Activity"
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
        style       : 'group-settings-context badge'
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
    slugLink = if slug is KD.defaultSlug then '/' else "/#{slug}/"
    KD.getSingleton('router').handleRoute slugLink, state:group
    event.stopPropagation()
    event.preventDefault()
    #KD.getSingleton("appManager").tell "Groups", "createContentDisplay", group

  viewAppended: JView::viewAppended

  setFollowerCount:(count)-> @$('.followers a').html count

  markPendingRequest:->
    @setClass "pending-request"
    @settingsButton.options.style += " pending-request"
    @memberBadge.updatePartial "<span class='fold'/>Request Pending"

  markPendingInvitation:->
    @setClass "pending-invitation"
    @settingsButton.options.style += " pending-invitation"
    @memberBadge.updatePartial "<span class='fold'/>Pending Invitation"

  markMemberGroup:(updatePartial=no)->
    @setClass "group-member"
    @settingsButton.options.style += " group-member"
    @fetchMembers() if @getData().privacy isnt 'public'
    @memberBadge.updatePartial "<span class='fold'/>You are a member" if updatePartial

  markOwnGroup:->
    @setClass "group-owner"
    @settingsButton.options.style += " group-owner"
    @memberBadge.stopUpdatingPartial = yes
    @memberBadge.updatePartial "<span class='fold'/>You are owner"

  markGroupAdmin:->
    @setClass "group-admin"
    @settingsButton.options.style += " group-admin"
    unless @memberBadge.stopUpdatingPartial?
      @memberBadge.updatePartial "<span class='fold'/>You are an admin"

  applyTextExpansions:(body)->
    if body?.length > 800
      @utils.applyTextExpansions body, yes
    else body

  click: KD.utils.showMoreClickHandler

  pistachio:->
    """
    <div class="wrapper">
      {h3{> @titleLink}}
      <p>
        {{> @memberCount}}
      </p>
      {article{ @applyTextExpansions #(body)}}
    </div>
    <div class='members-list-wrapper hidden'>
      {{> @members}}
    </div>
    <div class='side-wrapper'>
      <div class='badge-wrapper clearfix'>
        {{> @settingsButton}}
        {{> @memberBadge}}
        {{> @privateBadge}}
      </div>
    </div>
    """

  settingsMenu:(data)->

    menu = {}

    if data.slug isnt 'koding' # KD.defaultSlug
      menu['Leave Group'] =
        cssClass : 'leave-group'
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
                  @leaveGroup data, (err)=>
                    unless err
                      @memberBadge.hide()
                      @settingsButton.hide()
                      @unsetClass 'group-owner'
                    modal.buttons.Leave.hideLoader()
                    modal.destroy()
              Cancel       :
                style      : "modal-cancel"
                callback   : (event)-> modal.destroy()

      menu['Remove Group'] =
        cssClass : 'remove-group'
        callback : =>
          modal = new GroupsDangerModalView
            action     : 'Remove Group'
            longAction : 'remove this group'
            callback   : (callback)=>
              data.remove (err)=>
                callback()
                if err
                  return new KDNotificationView title: if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
                new KDNotificationView title:'Successfully removed!'
                modal.destroy()
                @destroy()
          , data

      menu['Cancel Request'] =
        cssClass : 'cancel-request'
        callback : =>
          modal = new KDModalView
            title          : 'Cancel Request'
            content        : "<div class='modalformline'>Are you sure that you want to cancel your membership request to this group?</div>"
            height         : 'auto'
            overlay        : yes
            buttons        :
              Cancel       :
                style      : "modal-clean-red"
                loader     :
                  color    : "#ffffff"
                  diameter : 16
                callback   : =>
                  @cancelRequest data, =>
                    @memberBadge.hide()
                    @settingsButton.hide()
                    @unsetClass 'group-owner'
                    modal.buttons.Cancel.hideLoader()
                    modal.destroy()
              Dismiss      :
                style      : "modal-cancel"
                callback   : (event)-> modal.destroy()

      menu['Accept Invitation'] =
        cssClass : 'accept-invitation'
        callback : @bound 'acceptInvitation'

      menu['Ignore Invitation'] =
        cssClass : 'ignore-invitation'
        callback : @bound 'ignoreInvitation'

    return menu

  leaveGroup:(group, callback)->
    group.leave @handleBackendResponse 'Successfully left group!', (err)->
      unless err
        currentGroup = KD.getSingleton('groupsController').getCurrentGroup()
        currentGroupSlug = currentGroup.getAt 'slug'
        if group.slug is currentGroupSlug
          document.location.reload()
      callback err

  cancelRequest:(group, callback)->
    KD.whoami().cancelRequest group, @handleBackendResponse 'Successfully canceled the request!', callback

  acceptInvitation:->
    KD.whoami().acceptInvitation @getData(), @handleBackendResponse 'Successfully accepted the invitation!', (err)=>
      unless err
        @markMemberGroup yes
        @unsetClass 'pending-invitation'
        @settingsButton.options.style = @settingsButton.options.style.replace ' pending-invitation', ''

  ignoreInvitation:->
    KD.whoami().ignoreInvitation @getData(), @handleBackendResponse 'Successfully ignored the invitation!', (err)=>
      @unsetClass 'pending-invitation' unless err

  handleBackendResponse:(successMsg, callback)->
    (err)->
      if err
        warn err
        new KDNotificationView
          title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
          duration : 2000
        return callback err

      new KDNotificationView
        title    : successMsg
        duration : 2000

      callback null

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
    @avatar = new AvatarView
      size      :
        width   : @getOptions().childOptions?.avatarWidth or 40
        height  : @getOptions().childOptions?.avatarHeight or 40
      # detailed  : yes
      tooltip   :
        title   : KD.utils.getFullnameFromAccount account
    , account

  viewAppended:JView::viewAppended

  pistachio:-> "{{> @avatar}}"
