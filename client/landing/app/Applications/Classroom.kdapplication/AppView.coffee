class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom"

    super options, data

    @cdnRoot     = "http://fatihacet.kd.io/cdn/classes"
    @appStorage  = new AppStorage "Classroom", "1.0"

    @createHeader()
    @fetchClasses()

  fetchClasses: ->
    @appStorage.fetchStorage (storage) =>
      @enrolledClasses   = @appStorage.getValue("EnrolledClasses") or []
      @relatedClasses    = []
      enrolledClassNames = []

      enrolledClassNames.push enrolled.name for enrolled in @enrolledClasses

      for classDetails in @getPredefinedClasses()
        className = classDetails.name
        if @enrolledClasses.length is 0 or enrolledClassNames.indexOf(className) is -1
          @relatedClasses.push classDetails

      @addSubView @classesView = new ClassroomClassesView
        delegate : this
      ,
        enrolled : @enrolledClasses
        related  : @relatedClasses

  createHeader: ->
    @addSubView @header = new KDView
      cssClass : "container"
      partial  : """
        <div class="banner">
          <h1>&lt;classroom /&gt;</h1>
          <h2>Start learning, teaching and sharing together. <br /> It's your classroom and it's online and it's free!</h2>
          <img src="http://hindiurduflagship.org/wp-content/uploads/2010/11/ImportanceVideoThumbnail.jpg" />
        </div>
      """

  enrollToClass: (classData) ->
    @enrolledClasses.push classData
    @appStorage.setValue "EnrolledClasses", @enrolledClasses

  cancelEnrollment: (classData) ->
    pos = i for enrolled, i in @enrolledClasses when enrolled.name is classData.name
    @enrolledClasses.splice pos, 1
    @appStorage.setValue "EnrolledClasses", @enrolledClasses
    if @classesView.enrolledContainer.getSubViews().length is 1
      @classesView.noEnrolledClass.show()

  getPredefinedClasses: ->
    [
      {
        devMode    : true
        version    : "0.1"
        name       : "CoffeeScript"
        author     : "Fatih Acet"
        authorNick : "fatihacet"
        icns       :
          "128"    : "./resources/icon.128.png"
      }
      {
        devMode    : true
        version    : "0.1"
        name       : "JavaScript"
        author     : "Fatih Acet"
        authorNick : "fatihacet"
        icns       :
          "128"    : "./resources/icon.128.png"
      }
      {
        devMode    : true
        version    : "0.1"
        name       : "PHP"
        author     : "Fatih Acet"
        authorNick : "fatihacet"
        icns       :
          "128"    : "./resources/icon.128.png"
      }
    ]