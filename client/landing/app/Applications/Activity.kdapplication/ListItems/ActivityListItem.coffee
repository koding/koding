class ActivityListItemView extends KDListItemView

  getActivityChildConstructors = ->
    JStatusUpdate       : StatusActivityItemView
    JCodeSnip           : CodesnipActivityItemView
    JQuestionActivity   : QuestionActivityItemView
    JDiscussion         : DiscussionActivityItemView
    JLink               : LinkActivityItemView
    JTutorial           : TutorialActivityItemView
    JBlogPost           : BlogPostActivityItemView

    NewMemberBucketData   : NewMemberBucketView

  getActivityChildCssClass = ->

    CFollowerBucket           : "system-message"
    CFolloweeBucket           : "system-message"
    CNewMemberBucket          : "system-message"
    CInstallerBucket          : "system-message"

    CFollowerBucketActivity   : "system-message"
    CFolloweeBucketActivity   : "system-message"
    CNewMemberBucketActivity  : "system-message"
    CInstallerBucketActivity  : "system-message"
    NewMemberBucketData       : "system-message"

  getBucketMap =->
    JAccount  : AccountFollowBucketItemView
    JTag      : TagFollowBucketItemView
    JApp      : AppFollowBucketItemView

  constructor:(options = {},data)->
    try
      console.log "1"
      options.type = "activity"
      console.log "1.1"
      super options, data
      console.log "1.2", data
      {constructorName} = data.bongo_
      console.log "2"
      @setClass getActivityChildCssClass()[constructorName]
      console.log "3"
      @bindTransitionEnd()
      console.log "4"
    catch e
      console.log ">>>>> ERROR >>>", e
      console.error e
    
  viewAppended:->
    @addChildView @getData()

  addChildView:(data, callback)->
    # return
    return unless data.bongo_
    {constructorName} = data.bongo_

    childConstructor =
      if /^CNewMemberBucket$/.test constructorName
        NewMemberBucketItemView
        # KDView
      else if /Bucket$/.test constructorName
        getBucketMap()[data.sourceName]
      else
        getActivityChildConstructors()[constructorName]

    if childConstructor
      childView = new childConstructor
        delegate : @
      , data
      @addSubView childView
      callback?()

  partial:-> ''

  show:(callback)->

    @getData().fetchTeaser? (err, teaser)=>
      @addChildView teaser, => @slideIn()

  slideIn:(callback=noop)->
    @once 'transitionend', callback.bind @
    @unsetClass 'hidden-item'

  slideOut:(callback=noop)->
    @once 'transitionend', callback.bind @
    @setClass 'hidden-item'
