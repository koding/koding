class BugReportMainView extends KDScrollView

  constructor:(options = {}, data)->
    super options, data

    @filterMenu = new KDSelectBox
      cssClass      : "bug-status"
      selectOptions : [
        { title : "all"     , value : "all"         }
        { title : "fixed"     , value : "fixed"     }
        { title : "postponed" , value : "postponed" }
        { title : "not repro" , value : "not repro" }
        { title : "duplicate" , value : "duplicate" }
        { title : "by design" , value : "by design" }
      ]
      callback      : ->
        log "Need to filter bug report feeder "

    @inputWidget = new ActivityInputWidget

    @addSubView @inputWidget
    @addSubView @filterMenu

  viewAppended:->
    KD.remote.api.JTag.one slug:"bug", (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]
