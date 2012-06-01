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
    # log "and evar here?????",@getData().fetchTeaser?
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

    @commentBox = new CommentView null, data
    @actionLinks = new ActivityActionsView delegate : @commentBox.commentList, cssClass : "comment-header", data
    super
    
    @getData().watch 'repliesCount', (count)=>
      @commentBox.decorateCommentedState() if count >= 0
    
    @contentDisplayController = @getSingleton "contentDisplayController"

  displayTags:(tags=[])->
    # log @getData(),tags
    suffix = ''
    tagsToDisplay = if tags?.length > 3
      suffix = '...'
      tags.slice(0,3)
    else
      tags

    'in ' + tagsToDisplay.map(
      (tag)-> "<span class='ttag'>#{tag.title}</span>"
    ).join('') + suffix
