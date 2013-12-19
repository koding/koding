class BugReportMainView extends KDScrollView

  constructor:(options = {}, data)->
    super options, data

    @filterMenu = new KDSelectBox
      selectOptions : [
        { title : "all"       , value : "all"       }
        { title : "fixed"     , value : "fixed"     }
      ]
      callback     : (formData)=>
        feedController =  @getOptions()
        feedController.selectFilter formData

    @inputWidget = new ActivityInputWidget

    @addSubView @filterMenu
    @addSubView @inputWidget

  viewAppended:->
    KD.remote.api.JTag.one slug:"bug", (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]
