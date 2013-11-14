class ClassroomCourseThumbView extends JView

  constructor: (options = {}, data) ->

    options.tagName = "figure"

    super options, data

    @createElements()

    data    = @getData()
    appView = @getDelegate()

    @on "EnrollmentRequested",   => appView.enrollToCourse data
    @on "EnrollmentCancelled",   => appView.cancelEnrollment data
    @on "ImportedCourseRemoved", => appView.cancelEnrollment data, "Imported"

  createElements: ->
    {type}             = @getOptions()
    data               = @getData()
    devModeOptions     =
      partial          : "Imported"
      cssClass         : "top-badge orange"
      tooltip          :
        title          : "This course is exported from somewhere else."
    cancelIconOptions  = {}
    @progressContainer = new KDView
      cssClass         : "progress-container"

    if data.devMode
      devModeOptions.cssClass = "top-badge gray"
      devModeOptions.partial  = "Dev Mode"
      devModeOptions.tooltip  =
        title                 : "This course is under development."

    @devMode = new KDCustomHTMLView devModeOptions

    if type is "enrolled" or type is "imported"
      cancelIconOptions.tagName  = "span"
      cancelIconOptions.cssClass = "icon delete"
      cancelIconOptions.click    = (e) =>
        e.stopPropagation()
        @destroy()
        @emit "EnrollmentCancelled"   if type is "enrolled"
        @emit "ImportedCourseRemoved" if type is "imported"

      percent = if data.completed then Math.round (100 * data.completed.length) / data.totalChapters else 0
      title   = if percent is 100 then "You completed this course" else "You completed #{percent}% of this course."

      @progressContainer.addSubView new KDView
        cssClass   : "progress-bar"
        attributes :
          style    : "width:#{percent}%"
        tooltip    :
          title    : title
    else
      @progressContainer.setClass "hidden"

    @cancelIcon = new KDCustomHTMLView cancelIconOptions

  click: ->
    data    = @getData()
    appView = @getDelegate()
    chapter = data.chapter

    KD.getSingleton("router").handleQuery "?course=#{data.name}"
    if ["enrolled", "imported"].indexOf(@getOptions().type) is -1
      @emit "EnrollmentRequested", data

  pistachio: ->
    data      = @getData()
    {cdnRoot} = @getOptions()
    return """
      {{> @devMode}}
      <p>
        <img src="#{data.resourcesRoot}/#{data.icns["128"]}" />
      </p>
      <div class="icon-container">
        {{> @cancelIcon}}
      </div>
      <cite>
        {{ #(name)}}
        {{ #(version)}}
      </cite>
      {{> @progressContainer}}
    """
