class ActivityListItemView extends KDListItemView
  
  getActivityChildConstructors = ->
    # CStatusActivity     : StatusActivityItemView
    JStatusUpdate       : StatusActivityItemView
    # CCodeSnipActivity   : CodesnipActivityItemView
    JCodeSnip           : CodesnipActivityItemView
    JQuestionActivity   : QuestionActivityItemView
    JDiscussionActivity : DiscussionActivityItemView
    JLinkActivity       : LinkActivityItemView
    
  getActivityChildCssClass = ->
    CFollowerBucket     : "system-message"
    CFolloweeBucket     : "system-message"
    CNewMemberBucket    : "system-message"
  
  getBucketMap =->
    JAccount  : AccountFollowBucketItemView
    JTag      : TagFollowBucketItemView
  
  constructor:(options,data)->
    options = options ? {}
    options.type = "activity"
    super options, data
    {constructorName} = data.bongo_
    @setClass getActivityChildCssClass()[constructorName]
    

    unless options.isHidden
      if 'function' is typeof data.fetchTeaser
        data.fetchTeaser? (err, teaser)=> @addChildView teaser
      else
        @addChildView data
        
  addChildView:(data,callback)->
    {constructorName} = data.bongo_
    childConstructor = 
      if /CNewMemberBucket$/.test constructorName
        NewMemberBucketItemView
      else if /Bucket$/.test constructorName
        getBucketMap()[data.sourceName]
      else
        getActivityChildConstructors()[constructorName]
    if childConstructor
      childView = new childConstructor({}, data)
      @addSubView childView
      callback?()

  partial:-> ''
  
  show:->
    @getData().fetchTeaser? (err, teaser)=>
      # log teaser,":::"
      @addChildView teaser, =>
        @slideIn()
  
  # render:->

  slideIn:(callback)->
    @$()
      .show()
      .animate({backgroundColor : "#FDF5D9", left : 0}, 400)
      .delay(500)
      .animate {backgroundColor : "#ffffff"}, 400, ()->
        $(this)
          .css({backgroundColor : "transparent"})
          .removeClass('hidden-item')
        callback?()
  
class ActivityItemChild extends KDView

  constructor:(options, data)->
    origin = {
      constructorName  : data.originType
      id               : data.originId
    }
    @avatar = new AvatarView {
      size    : {width: 40, height: 40}
      origin
    }
    @author = new ProfileLinkView {
      origin
    }
    
    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
    , data.tags
    
    @commentBox = new CommentView null, data
    @actionLinks = new ActivityActionsView delegate : @commentBox.commentList, cssClass : "comment-header", data
    
    if data.originId is KD.whoami().getId()
      @settingsButton = new KDButtonViewWithMenu
        style       : 'transparent activity-settings-context'
        cssClass    : 'activity-settings-menu'
        title       : ''
        icon        : yes
        delegate    : @
        iconClass   : "arrow"
        menu        : [
          type      : "contextmenu"
          items     : [
#            { title : 'Edit',   id : 1,  parentId : null, callback : => new KDNotificationView type : "mini", title : "<p>Currently disabled.</p>" }
            { title : 'Edit',   id : 1,  parentId : null, callback : => @getSingleton('mainController').emit 'ActivityItemEditLinkClicked', data }
            { title : 'Delete', id : 2,  parentId : null, callback : => @confirmDeletePost data  }
          ]
        ]
        callback    : (event)=> @settingsButton.contextMenu event
    else
      @settingsButton = new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'
    
    super
    
    data.on 'TagsChanged', (tagRefs)=>
      bongo.cacheable tagRefs, (err, tags)=>
        @getData().setAt 'tags', tags
        @tags.setData tags
        @tags.render()
    
    data.on 'PostIsDeleted', =>
      if KD.whoami().getId() is data.getAt('originId')
        @parent.destroy()
      else
        @parent.putOverlay
          isRemovable : no
          parent      : @parent
          cssClass    : 'half-white'
    
    @getData().watch 'repliesCount', (count)=>
      @commentBox.decorateCommentedState() if count >= 0
    
    @contentDisplayController = @getSingleton "contentDisplayController"
  
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
