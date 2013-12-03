class ActivityItemChild extends KDView

#  showAuthor =(author)->
#    KD.getSingleton('router').handleRoute "/#{author.profile.nickname}", state: author

  constructor:(options, data)->

    currentGroup = KD.getSingleton("groupsController").getCurrentGroup()

    getContentGroupLinkPartial = (groupSlug, groupName)->
      if currentGroup?.slug is groupSlug
      then ""
      else "In <a href=\"#{groupSlug}\" target=\"#{groupSlug}\">#{groupName}</a>"

    @contentGroupLink = new KDCustomHTMLView
      tagName     : "span"
      partial     : getContentGroupLinkPartial(data.group, data.group)

    if currentGroup?.slug is data.group
      @contentGroupLink.updatePartial getContentGroupLinkPartial(currentGroup.slug, currentGroup.title)
    else
      KD.remote.api.JGroup.one {slug:data.group}, (err, group)=>
        if not err and group
          @contentGroupLink.updatePartial getContentGroupLinkPartial(group.slug, group.title)

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarView {
      size        : {width: 86, height: 86}
      cssClass    : "author-avatar"
      origin
      showStatus  : yes
    }

    @author = new ProfileLinkView { origin }

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      itemClass  : TagLinkView
    , data.tags


    # for discussion, switch to the View that supports nested structures
    # JDiscussion,JTutorial
    # -> JOpinion
    #    -> JComment
    if data.bongo_.constructorName in ["JDiscussion","JTutorial"]
      @commentBox = new OpinionView null, data
      list        = @commentBox.opinionList
    else
      commentSettings = options.commentSettings or null
      @commentBox = new CommentView commentSettings, data
      list        = @commentBox.commentList

    @actionLinks = new ActivityActionsView
      cssClass : "comment-header"
      delegate : list
    , data

    account = KD.whoami()
    if (data.originId is KD.whoami().getId()) or KD.checkFlag 'super-admin'
      @settingsButton = new KDButtonViewWithMenu
        cssClass    : 'transparent activity-settings-menu'
        title       : ''
        icon        : yes
        delegate    : @
        iconClass   : "arrow"
        menu        : @settingsMenu data
        callback    : (event)=> @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    super options, data

    data = @getData()
    data.on 'TagsChanged', (tagRefs)=>
      KD.remote.cacheable tagRefs, (err, tags)=>
        @getData().setAt 'tags', tags
        @tags.setData tags
        @tags.render()

    deleteActivity = (activityItem)->
      activityItem.slideOut -> activityItem.destroy()

    @on 'ActivityIsDeleted', =>
      activityItem = @getDelegate()
      deleteActivity activityItem

    data.on 'PostIsDeleted', =>
      activityItem = @getDelegate()
      return unless activityItem.isInDom()

      if KD.whoami().getId() is data.getAt('originId')
        deleteActivity activityItem
      else
        activityItem.putOverlay
          isRemovable : no
          parent      : @parent
          cssClass    : 'half-white'

        @utils.wait 30000, ->
          activityItem.slideOut -> activityItem.destroy()


    data.watch 'repliesCount', (count)=>
      @commentBox.decorateCommentedState() if count >= 0

    KD.remote.cacheable data.originType, data.originId, (err, account)=>
      @setClass "exempt" if account and KD.checkFlag 'exempt', account

  settingsMenu:(data)->

    account        = KD.whoami()
    mainController = KD.getSingleton('mainController')
    activityController = KD.getSingleton('activityController')

    if data.originId is KD.whoami().getId()
      menu =
        'Edit'     :
          callback : ->
            mainController.emit 'ActivityItemEditLinkClicked', data
        'Delete'   :
          callback : =>
            @confirmDeletePost data

      return menu

    if KD.checkFlag 'super-admin'
      if KD.checkFlag 'exempt', account
        menu =
          'Unmark User as Troll' :
            callback             : ->
              activityController.emit "ActivityItemUnMarkUserAsTrollClicked", data
      else
        menu =
          'Mark User as Troll' :
            callback           : ->
              activityController.emit "ActivityItemMarkUserAsTrollClicked", data

      menu['Delete Post'] =
        callback : =>
          @confirmDeletePost data

      menu['Block User'] =
        callback : ->
          activityController.emit "ActivityItemBlockUserClicked", data.originId

      return menu


  confirmDeletePost:(data)->

    modal = new KDModalView
      title          : "Delete post"
      content        : "<div class='modalformline'>Are you sure you want to delete this post?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>

            if data.fake
              @emit 'ActivityIsDeleted'
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              return

            data.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              unless err then @emit 'ActivityIsDeleted'
              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title     : "Error, please try again later!"
        Cancel       :
          style      : "modal-cancel"
          title      : "cancel"
          callback   : ->
            modal.destroy()

    modal.buttons.Delete.blur()

  click: KD.utils.showMoreClickHandler

  viewAppended:->
    super

    if @getData().fake
      @actionLinks.setClass 'hidden'

