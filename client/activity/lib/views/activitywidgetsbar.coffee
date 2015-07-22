kd                         = require 'kd'
KDCustomHTMLView           = kd.CustomHTMLView
checkFlag                  = require 'app/util/checkFlag'
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

    if checkFlag ['super-admin', 'super-digitalocean']
      @addSubView new ActivityAnnouncementWidget
    @addSubView new ActivityGuideWidget
    @addSubView new ActivityTopicsWidget
    @addSubView new ActivityUniversityWidget
    @addSubView new ActivitySocialMediaWidget
