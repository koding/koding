class GroupHomeView extends KDView

  constructor:(options, data)->

    super options, data

  viewAppended:->
    entryPoint = @getOption 'entryPoint'
    groupsController = @getSingleton "groupsController"
    # groupsController.on "GroupChanged", (name, group)->
    KD.remote.cacheable entryPoint, (err, models)=>
      if err then callback err
      else if models?
        [group] = models
        @setData group

        @readmeView = new GroupReadmeView {}, group

        JView::viewAppended.call @

  pistachio:->
    """
      <h1> Dat is da {{ #(title)}} groop!</h1>
      {{> @readmeView}}
    """