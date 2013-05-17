class ActivityItemChild extends KDView

#  showAuthor =(author)->
#    KD.getSingleton('router').handleRoute "/#{author.profile.nickname}", state: author

  constructor:(options, data)->

    origin =
      constructorName  : data.originType
      id               : data.originId

    @avatar = new AvatarView {
      size    : {width: 40, height: 40}
      origin
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
      @commentBox = new CommentView null, data
      list        = @commentBox.commentList

    @actionLinks = new ActivityActionsView
      cssClass : "comment-header"
      delegate : list
    , data

    account = KD.whoami()
    if (data.originId is KD.whoami().getId()) or KD.checkFlag 'super-admin'
      @settingsButton = new KDButtonViewWithMenu
        cssClass    : 'transparent activity-settings-context activity-settings-menu'
        title       : ''
        icon        : yes
        delegate    : @
        iconClass   : "arrow"
        menu        : @settingsMenu data
        callback    : (event)=> @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    super

    data = @getData()
    data.on 'TagsChanged', (tagRefs)=>
      KD.remote.cacheable tagRefs, (err, tags)=>
        @getData().setAt 'tags', tags
        @tags.setData tags
        @tags.render()

    data.on 'PostIsDeleted', =>
      activityItem = @getDelegate()
      if KD.whoami().getId() is data.getAt('originId')
        activityItem.slideOut -> activityItem.destroy()
      else
        activityItem.putOverlay
          isRemovable : no
          parent      : @parent
          cssClass    : 'half-white'

        @utils.wait 30000, ->
          activityItem.slideOut -> activityItem.destroy()


    data.watch 'repliesCount', (count)=>
      @commentBox.decorateCommentedState() if count >= 0

    @contentDisplayController = @getSingleton "contentDisplayController"

    KD.remote.cacheable data.originType, data.originId, (err, account)=>
      @setClass "exempt" if account and KD.checkFlag 'exempt', account

  settingsMenu:(data)->

    account        = KD.whoami()
    mainController = @getSingleton('mainController')

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
      if data.isLowQuality
        menu =
          'Unmark User as Troll' :
            callback             : ->
              mainController.unmarkUserAsTroll data
      else
        menu =
          'Mark User as Troll' :
            callback           : ->
              mainController.markUserAsTroll data

      menu['Delete Post'] =
        callback : =>
          @confirmDeletePost data

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
            data.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              unless err then @emit 'ActivityIsDeleted'
              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title     : "Error, please try again later!"

  click:(event)->
    $trg = $(event.target)
    more = "span.collapsedtext a.more-link"
    less = "span.collapsedtext a.less-link"
    $trg.parent().addClass("show").removeClass("hide") if $trg.is(more)
    $trg.parent().removeClass("show").addClass("hide") if $trg.is(less)

  viewAppended:->
    super

    if @getData().fake
      @actionLinks.setClass 'hidden'

