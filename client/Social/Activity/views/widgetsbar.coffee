class ActivityWidgetsBar extends KDCustomHTMLView

  constructor: (options = {}) ->

    options.cssClass = KD.utils.curry 'activity-widgets-bar', options.cssClass
    options.tagName  = 'aside'

    super options

    @addSubView new ActivityGuideWidget
    @addSubView new ActivityTopicsWidget
    @addSubView new ActivityUniversityWidget