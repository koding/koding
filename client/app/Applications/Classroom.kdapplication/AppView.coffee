class ClassroomAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @container = new KDView
      partial  : "HELLLO"
      cssClass : "classroom"