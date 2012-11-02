class ActivityContentDisplay extends KDScrollView

  constructor:(options = {}, data)->

    options.cssClass or= "content-display activity-related #{options.type}"

    super

    @header = new HeaderViewSection
      type    : "big"
      title   : @getOptions().title

    @back   = new KDCustomHTMLView
      tagName : "a"
      partial : "<span>&laquo;</span> Back"
      click   : =>
        log 'history:back'; history.back(); no#@getSingleton("contentDisplayController").emit "ContentDisplayWantsToBeHidden", @




#     # disabled for beta
#     # @getView().addSubView metaSection = new KDView cssClass : "content-display-meta"
#     # metaSection.addSubView meta = new ContentDisplayScoreBoard cssClass : "scoreboard",activity
#     # metaSection.addSubView tagHead = new KDHeaderView title : "Tags"
#     # metaSection.addSubView metaTags = new ContentDisplayTags