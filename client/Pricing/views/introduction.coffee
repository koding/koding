class PricingIntroductionView extends KDView
  constructor: (options = {}, data) ->
    options.tagName = "section"
    options.cssClass = "introduction"
    super options, data

  viewAppended: ->
    @addSubView new KDHeaderView
      type      : 'medium'
      title     : 'Simple pricing for any team or developer'

    @addSubView new KDCustomHTMLView
      tagName   : 'p'
      partial   : 'Which one describes your current situation?'

    router         = KD.singleton 'router'
    currentSection = router.currentPath.split('/')[2]

    @addSubView new KDMultipleChoice
      labels        : ['Developer', 'Team']
      defaultValue  : [currentSection]
      multiple      : no
      callback      : (state) -> router.handleRoute "/Pricing/#{state}"
