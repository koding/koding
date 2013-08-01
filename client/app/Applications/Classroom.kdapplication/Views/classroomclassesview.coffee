class ClassroomClassesView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "user-classes-view"

    super options, data

    @enrolledClassNames = []
    @relatedClassNames  = []

    @createElements()
    @createClasses()

  createClasses: ->
    if @getData().enrolled
      for enrolled in @getData().enrolled
        @enrolledClassNames.push enrolled.name
        @createThumbView @enrolledContainer, "enrolled", enrolled

    if @getData().related
      for related in @getData().related
        @relatedClassNames.push related.name
        @createThumbView @relatedContainer, "related", related

  createThumbView: (container, type, data) ->
    appView   = @getDelegate()
    {cdnRoot} = appView
    thumbView = new ClassroomClassThumbView { cdnRoot, type, delegate: appView }, data
    container.addSubView thumbView

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

    @noRelatedClass.show()   unless @getData().related.length
    @noEnrolledClass.show()  unless @getData().enrolled.length

  pistachio: ->
    """
      {{> @enrolledContainer}}
      {{> @relatedContainer}}
    """