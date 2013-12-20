class BugReportMainView extends KDScrollView

  constructor:(options = {}, data)->
    super options, data
    @filterMenu = new KDSelectBox
      cssClass      : "bug-status"
      selectOptions : [
        { title : "all"       , value : "all"       }
        { title : "fixed"     , value : "fixed"     }
        { title : "changelog" , value : "changelog" }
      ]
      callback     : (formData)=>
        feedController = @getOptions()
        feedController.selectFilter formData

    @inputWidget = new ActivityInputWidget

    @addSubView @inputWidget
    @addSubView @filterMenu

  viewAppended:->
    KD.remote.api.JTag.one slug:"bug", (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]
