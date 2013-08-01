class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom"

    super options, data

    @cdnRoot     = "http://fatihacet.kd.io/cdn/classes"
    @appStorage  = new AppStorage "Classroom", "1.0"

    @createHeader()
    @fetchClasses()

  fetchClasses: ->
    predefinedClasses = [ "CoffeeScript", "JavaScript", "PHP" ]

    @appStorage.fetchStorage (storage) =>
      @enrolledClasses = @appStorage.getValue "UserClasses"
      @relatedClasses  = []

      for className in predefinedClasses
        if @enrolledClasses
          if @enrolledClasses.indexOf(className) is -1
            @relatedClasses.push className
        else
          @relatedClasses.push className

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