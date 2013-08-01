class ClassroomClassesView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "user-classes-view"

    super options, data

    @createElements()
    @createClasses()

  createClasses: ->
    @thumbViews = []

    if @getData().enrolled
      for enrolled in @getData().enrolled
        @createThumbView @enrolledContainer, "enrolled", enrolled

    if @getData().related
      for related in @getData().related
        @createThumbView @relatedContainer, "related", related

  createThumbView: (container, type, data) ->
    {cdnRoot} = @getDelegate()
    thumbView = new ClassroomClassThumbView { cdnRoot, type }, data
    container.addSubView thumbView
    @thumbViews.push thumbView

  createElements: ->
    @enrolledContainer = new KDCustomHTMLView
      cssClass         : "enrolled-clases classes"
      partial          : """<p class="title">Your Classes</p>"""

    @noEnrolledClass   = new KDCustomHTMLView
      tagName          : "p"
      cssClass         : "no-enrolled-class hidden"
      partial          : "You didn't start a class. Enroll now!"

    @relatedContainer  = new KDCustomHTMLView
      cssClass         : "related-clases classes"
      partial          : """<p class="title">Related Classes</p>"""

    @noRelatedClass    = new KDCustomHTMLView
      tagName          : "p"
      cssClass         : "no-related-class hidden"
      partial          : "Currently there is no related class with your enrolled classes."

    @enrolledContainer.addSubView @noEnrolledClass
    @relatedContainer.addSubView  @noRelatedClass

    @noRelatedClass.show()   unless @getData().related
    @noEnrolledClass.show()  unless @getData().enrolled

  viewAppended: ->
    super
    thumbView.loader.show() for thumbView in @thumbViews

  pistachio: ->
    """
      {{> @enrolledContainer}}
      {{> @relatedContainer}}
    """