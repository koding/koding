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

    constructorName = data.type
    @setClass getActivityChildCssClass()[constructorName]

  viewAppended:->
    @addChildView @getData()

    # data = @getData()
    # @addSubView @loader = new KDLoaderView
    #   size          :
    #     width       : 20
    #   loaderOptions :
    #     color       : "#ff9200"
    #     speed       : 2
    # @utils.wait 100, =>
    #   @loader.show()
    # if data.type is "CNewMemberBucketActivity"
    #   @addChildView @getData()

  # setModel:(model)->
  #   # unless @getOptions().isHidden
  #     # if 'function' is typeof model.fetchTeaser
  #     #   model.fetchTeaser? (err, teaser)=>
  #     #     @loader.destroy()
  #     #     @updatePartial ""
  #     #     @addChildView teaser
  #     # else
  #   if model.snapshot
  #     model.snapshot = model.snapshot.replace /&quot;/g, '"'
  #     KD.remote.reviveFromSnapshots [model], (err, instances)=>
  #       # log instances[0]
  #       @loader?.destroy()
  #       @addChildView instances[0]
  #   else
  #     @loader?.destroy()
  #     @addChildView model


  #   model.on 'ContentMarkedAsLowQuality', =>
  #     @hide() unless KD.checkFlag 'exempt'
  #   model.on 'ContentUnmarkedAsLowQuality', => @show()

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
      # to not to block the page
      # we use this timeout here
      @utils.wait =>
        @addSubView childView
        callback?()

  partial:-> ''

  show:(callback)->

    @getData().fetchTeaser? (err, teaser)=>
      @addChildView teaser, => @slideIn()

  slideIn:()-> @$().removeClass 'hidden-item'
