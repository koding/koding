class ClassroomCoursesView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "user-courses-view"

    super options, data

    @enrolledCourseNames = []
    @relatedCourseNames  = []

    @createElements()
    @createCourses()

  createCourses: ->
    if @getData().enrolled
      for enrolled in @getData().enrolled
        @enrolledCourseNames.push enrolled.name
        @createThumbView @enrolledContainer, "enrolled", enrolled

    if @getData().related
      for related in @getData().related
        @relatedCourseNames.push related.name
        @createThumbView @relatedContainer, "related", related

  createThumbView: (container, type, data) ->
    appView        = @getDelegate()
    {cdnRoot}      = appView
    data.completed = @getData().completedChapters?[data.name]
    thumbView      = new ClassroomCourseThumbView { cdnRoot, type, delegate: appView }, data
    container.addSubView thumbView

  createElements: ->
    @enrolledContainer = new KDCustomHTMLView
      cssClass         : "enrolled-courses courses"
      partial          : """<p class="title">Your Courses</p>"""

    @noEnrolledCourse  = new KDCustomHTMLView
      tagName          : "p"
      cssClass         : "no-enrolled-course hidden"
      partial          : "You didn't enrolled a course. Enroll now!"

    @relatedContainer  = new KDCustomHTMLView
      cssClass         : "related-courses courses"
      partial          : """<p class="title">Related Courses</p>"""

    @noRelatedCourse   = new KDCustomHTMLView
      tagName          : "p"
      cssClass         : "no-related-course hidden"
      partial          : "Currently there is no related course with your enrolled courses."

    @enrolledContainer.addSubView @noEnrolledCourse
    @relatedContainer.addSubView  @noRelatedCourse

    @noRelatedCourse.show()   unless @getData().related.length
    @noEnrolledCourse.show()  unless @getData().enrolled.length

  pistachio: ->
    """
      {{> @enrolledContainer}}
      {{> @relatedContainer}}
    """