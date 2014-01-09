class ClassroomCoursesView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "user-courses-view"

    super options, data

    @createElements()
    @createCourses()

  createCourses: ->
    {enrolled, related, imported} = @getData()

    for own courseName, courseManifest of enrolled
      @createThumbView @enrolledContainer, "enrolled", courseManifest

    for own courseName, courseManifest of imported
      @createThumbView @enrolledContainer, "imported", courseManifest

    for own courseName, courseManifest of related
      @createThumbView @relatedContainer, "related", courseManifest

  createThumbView: (container, type, data) ->
    delegate       = @getDelegate()
    data.completed = @getData().completed[data.name] is yes
    container.addSubView new ClassroomCourseThumbView { type, delegate }, data

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

    data = @getData()
    unless Object.keys(data.enrolled).length or Object.keys(data.imported).length
      @noEnrolledCourse.show()

    unless Object.keys(data.related).length
      @noRelatedCourse.show()

  pistachio: ->
    """
      {{> @enrolledContainer}}
      {{> @relatedContainer}}
    """