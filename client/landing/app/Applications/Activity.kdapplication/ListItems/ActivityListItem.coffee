class ActivityListItemView extends KDListItemView

  getActivityChildConstructors = ->
    # CStatusActivity     : StatusActivityItemView
    JStatusUpdate       : StatusActivityItemView
    # CCodeSnipActivity   : CodesnipActivityItemView
    JCodeSnip           : CodesnipActivityItemView
    JQuestionActivity   : QuestionActivityItemView
    JDiscussion         : DiscussionActivityItemView
    JLink               : LinkActivityItemView
    JTutorial           : TutorialActivityItemView
    # THIS WILL DISABLE CODE SHARES
    JCodeShare            : CodeShareActivityItemView
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

    options.type = "activity"

    super options, data

    {constructorName} = data.bongo_
    @setClass getActivityChildCssClass()[constructorName]

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
      childView = new childConstructor({}, data)
      @addSubView childView
      callback?()

  partial:-> ''

  show:(callback)->

    @getData().fetchTeaser? (err, teaser)=>
      @addChildView teaser, => @slideIn()

  slideIn:(callback=noop)->
    @unsetClass 'hidden-item'
    @utils.wait 601, callback.bind @

  slideOut:(callback=noop)->
    @setClass 'hidden-item'
    @utils.wait 601, callback.bind @
