class BugReportMainView extends KDView

  createCommons:->
    @addSubView @header = new HeaderViewSection
      type  : "big"
      title : "Bugs"
