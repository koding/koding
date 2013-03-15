class StaticActivityListItemView extends ActivityListItemView

  getActivityChildConstructors = ->
    JStatusUpdate       : StaticStatusActivityItemView
    JCodeSnip           : StaticCodesnipActivityItemView
    JDiscussion         : StaticDiscussionActivityItemView
    JTutorial           : StaticTutorialActivityItemView
    JBlogPost           : StaticBlogPostActivityItemView

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
      else getActivityChildConstructors()[constructorName]

    if childConstructor
      childView = new childConstructor
        delegate : @
      , data
      @addSubView childView
      callback?()