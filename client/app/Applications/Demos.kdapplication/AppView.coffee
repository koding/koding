class DemosMainView extends KDScrollView

  viewAppended:()->

    @addSubView new KDSplitView
      colored : yes
      sizes   : ['20%', null, null]