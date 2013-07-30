class ClassroomAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @container = new KDView
      cssClass : "classroom"
      partial  : """
        <div class="container">
          <div class="banner">
            <h1>&lt;classroom /&gt;</h1>
            <h2>Start learning, teaching and sharing together. <br /> It's your classroom and it's online and it's free!</h2>
            <img src="http://hindiurduflagship.org/wp-content/uploads/2010/11/ImportanceVideoThumbnail.jpg" />
          </div>
        </div>
      """