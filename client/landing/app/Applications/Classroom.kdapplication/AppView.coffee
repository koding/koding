class ClassroomAppView extends KDScrollView

  constructor: (options = {}, data) ->

    options.cssClass = "classroom"

    super options, data

    @appStorage = new AppStorage "Classroom", "1.0"

    @createHeader()
    @fetchUserClasses()

  fetchUserClasses: ->
    @appStorage.fetchStorage (storage) =>

      @addSubView @classesView = new ClassroomClassesView
        delegate : this
      ,
        enrolled : @appStorage.getValue "UserClasses"

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