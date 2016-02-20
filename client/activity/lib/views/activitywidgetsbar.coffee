kd                         = require 'kd'
KDCustomHTMLView           = kd.CustomHTMLView
ActivityGuideWidget        = require './activityguidewidget'
ActivityTopicsWidget       = require './activitytopicswidget'
ActivityUniversityWidget   = require './activityuniversitywidget'
ActivitySocialMediaWidget  = require './activitysocialmediawidget'
ActivityAnnouncementWidget = require './activityannouncementwidget'


module.exports = class ActivityWidgetsBar extends KDCustomHTMLView

  constructor: (options = {}) ->

    options.cssClass = kd.utils.curry 'activity-widgets-bar', options.cssClass
    options.tagName  = 'aside'

    super options

    @addSubView new ActivityGuideWidget
    @addSubView new ActivityTopicsWidget
    @addSubView new ActivityUniversityWidget
    @addSubView new ActivitySocialMediaWidget
