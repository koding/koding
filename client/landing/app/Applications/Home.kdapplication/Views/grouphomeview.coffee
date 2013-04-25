class GroupHomeView extends KDView

  constructor:(options, data)->

    super options, data

    @setClass "screenshots"

    @homeLoginBar = new HomeLoginBar

  viewAppended:->
    entryPoint       = @getOption 'entryPoint'
    groupsController = @getSingleton "groupsController"

    KD.remote.cacheable entryPoint, (err, models)=>
      if err then callback err
      else if models?
        [group] = models
        @setData group
        @body = new KDScrollView
          domId     : 'home-group-body'
          tagName   : 'section'
          pistachio : """<div class='group-desc'>{{ #(body)}}</div>"""
        , group
        @readmeView = new GroupReadmeView {}, group
        JView::viewAppended.call @

  pistachio:->

    """
    {{> @body}}
    {{> @homeLoginBar}}
    {{> @readmeView}}
    """

