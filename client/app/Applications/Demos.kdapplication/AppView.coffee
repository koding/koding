class DemosMainView extends KDScrollView

  viewAppended:()->

    @addSubView split = new SlidingSplit
      type            : "horizontal"
      cssClass        : "chat-split"
      sizes           : [null]
      scrollContainer : @