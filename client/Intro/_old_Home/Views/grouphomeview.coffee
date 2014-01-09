class GroupHomeView extends KDView

  # roleEventMap =
  #   "guest"               : "statusGuest"
  #   "member"              : "statusMember"
  #   "invitation-pending"  : "statusPending"
  #   "invitation-sent"     : "statusActionRequired"
  #   "invitation-declined" : "statusDeclined"

  constructor:(options = {}, data)->

    options.domId    = "home-group-header"

    super options, data

  viewAppended:->
    {entryPoint}     = KD.config
    groupsController = KD.getSingleton "groupsController"

    KD.remote.cacheable entryPoint.slug, (err, models)=>
      if err then callback err
      else if models?
        [group] = models
        @setData group
        @addSubView @body = new KDScrollView
          domId     : 'home-group-body'
          tagName   : 'section'
          pistachio : """<div class='group-desc'>{{ #(body)}}</div>"""
        , group

        @addSubView @homeLoginBar = new HomeLoginBar
          domId : "group-home-links"
          @emit "ready"
