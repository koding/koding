class ActivityWidgetsBar extends KDCustomHTMLView
  constructor: (options = {}) ->
    options.cssClass    = 'activity-widgets-bar'
    options.tagName     = 'aside'
    super options

    @addSubView new ActivityGuideWidget
    @addSubView new ActivityTopicsWidget
    @addSubView new ActivityUniversityWidget