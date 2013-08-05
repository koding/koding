class ClassroomCourseThumbView extends JView

  constructor: (options = {}, data) ->

    options.tagName = "figure"

    super options, data

    @createElements()

    data    = @getData()
    appView = @getDelegate()

    @on "EnrollmentCancelled", => appView.cancelEnrollment data
    @on "EnrollmentRequested", => appView.enrollToCourse data

  createElements: ->
    data              = @getData()
    devModeOptions    = {}
    cancelIconOptions = {}

    if data.devMode
      devModeOptions.cssClass = "top-badge gray"
      devModeOptions.partial  = "Dev Mode"

    @devMode = new KDCustomHTMLView devModeOptions

    if @getOptions().type is "enrolled"
      cancelIconOptions.tagName  = "span"
      cancelIconOptions.cssClass = "icon delete"
      cancelIconOptions.click    = (e) =>
        e.stopPropagation()
        @destroy()
        @emit "EnrollmentCancelled"

    @cancelIcon = new KDCustomHTMLView cancelIconOptions

  click: ->
    data    = @getData()
    appView = @getDelegate()
    chapter = data.chapter

    KD.getSingleton("router").handleQuery "?course=#{data.name}"
    @emit "EnrollmentRequested", data  if @getOptions().type isnt "enrolled"

  pistachio: ->
    data      = @getData()
    {cdnRoot} = @getOptions()
    return """
      {{> @devMode}}
      <p>
        <img src="#{cdnRoot}/#{data.name}.kdcourse/#{data.icns['128']}" />
      </p>
      <div class="icon-container">
        {{> @cancelIcon}}
      </div>
      <cite>
        <span>#{data.name}</span>
        <span>#{data.version}</span>
      </cite>
    """
