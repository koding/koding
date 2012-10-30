class ActivityListItemView extends KDListItemView

  getActivityChildConstructors = ->
    # CStatusActivity     : StatusActivityItemView
    JStatusUpdate       : StatusActivityItemView
    # CCodeSnipActivity   : CodesnipActivityItemView
    JCodeSnip           : CodesnipActivityItemView
    JQuestionActivity   : QuestionActivityItemView
    JDiscussion         : DiscussionActivityItemView
    JLink               : LinkActivityItemView
    # THIS WILL DISABLE CODE SHARES
    JCodeShare            : CodeShareActivityItemView

  getActivityChildCssClass = ->

    CFollowerBucket           : "system-message"
    CFolloweeBucket           : "system-message"
    CNewMemberBucket          : "system-message"
    CInstallerBucket          : "system-message"

    CFollowerBucketActivity   : "system-message"
    CFolloweeBucketActivity   : "system-message"
    CNewMemberBucketActivity  : "system-message"
    CInstallerBucketActivity  : "system-message"

  getBucketMap =->
    JAccount  : AccountFollowBucketItemView
    JTag      : TagFollowBucketItemView
    JApp      : AppFollowBucketItemView

  constructor:(options = {},data)->

    options.type = "activity"

    super options, data

    data = @getData()

    {constructorName} = data.bongo_
    @setClass getActivityChildCssClass()[constructorName]

    unless options.isHidden
      if 'function' is typeof data.fetchTeaser
        data.fetchTeaser? (err, teaser)=>
          @addChildView teaser
      else
        @addChildView data

    data.on 'ContentMarkedAsLowQuality', =>
      @hide() unless KD.checkFlag 'exempt'
    data.on 'ContentUnmarkedAsLowQuality', => @show()

  addChildView:(data, callback)->

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

  show:(callback)->

    @getData().fetchTeaser? (err, teaser)=>
      @addChildView teaser, => @slideIn()

  slideIn:()-> @$().removeClass 'hidden-item'
