class GroupsBundleCreateView extends JView

  constructor:(options, data)->
    super

    {group} = @getData()

    @createButton = new KDButtonView
      style     : "clean-gray"
      title     : "Create bundle"
      callback  : =>
        group.createBundle (err, bundle) =>
          return error err  if err?

          @emit 'BundleCreated', bundle

  pistachio:->
    """
    <h3>Get started</h3>
    <p>This group doesn't have a bundle yet, but you can create one now!</p>
    {{> @createButton}}
    """

class GroupsBundleEditView extends JView

  computeUnitMap =
    vms   : 1
    cpu   : 1
    ram   : 0.25
    disk  : 0.5

  computeUnitVisibility =
    users : yes
    vms   : yes
    cpu   : no
    ram   : no
    disk  : no

  constructor: (options, data) ->
    super

    {group, bundle} = @getData()

    {JLimit} = KD.remote.api

    computeLimit = new JLimit { usage: 0, quota: 0, unit: 'VM', title: 'vms' }

    bundle.fetchLimits (err, limits) =>
      return error err      if err?
      limits.splice 1, 0, computeLimit
      @renderLimits limits  if limits?

    @usersLabel = new KDLabelView
      title       : 'Users'

    @usersSlider = new KDInputView
      label       : @usersLabel
      type        : 'range'
      change      : (event) =>
        userData = @limitsData.users
        userData.quota = @usersSlider.getValue()
        userData.emit 'update'
      attributes  :
        min       : 0
        max       : 50000

    @computeLabel = new KDLabelView
      title       : 'Computing resources'

    @computeSlider = new KDInputView
      label       : @computeLabel
      type        : 'range'
      change      : (event) =>
        computeValue = @computeSlider.getValue()
        ['cpu','ram','disk','vms'].forEach (resource) =>
          resourceData = @limitsData[resource]
          resourceData.quota = computeValue * computeUnitMap[resource]
          resourceData.emit 'update'
      attributes  :
        min       : 0
        max       : 50000

    @limits = new KDView
      tagName   : 'span'
      cssClass  : 'group-bundle-limits clearfix'

    @destroyButton = new KDButtonView
      style     : "modal-clean-red"
      title     : "Destroy bundle"
      callback  : =>
        group.destroyBundle (err, bundle) =>
          return error err  if err?

          @emit 'BundleDestroyed', bundle

    @saveButton = new KDButtonView
      style     : "modal-clean-green"
      title     : "Save bundle"
      callback  : =>
        overagePolicy = @overagePolicy.getValue()
        group.updateBundle { overagePolicy }

    @overageLabel = new KDLabelView
      title     : 'Overage policy'

    @overagePolicy = new KDSelectBox
      label       : @overageLabel
      name        : "overagePolicy"
      defaultValue: bundle.overagePolicy ? "not allowed"
      selectOptions : [
        { value : "not allowed",    title : "Not allowed" }
        { value : "by permission",  title : "Allowed only with admin approval" }
        { value : "allowed",        title : "Allowed for all members" }
      ]

  renderLimits: (limits) ->
    @limits.destroySubViews()
    @limitsData = {}
    for limit in limits
      @limitsData[limit.title] = limit
      cssClass = 'group-bundle-limit'
      cssClass += ' hidden'  unless computeUnitVisibility[limit.title]
      limitView = new GroupsBundleLimitView {cssClass}, limit
      @addSubView limitView

  pistachio: ->
    """
    <h3>Bundle details</h3>
    <p>There will be some cool details here.</p>
    <div class="group-bundle-plan-sliders clearfix">
      <div>{{> @usersLabel}} {{> @usersSlider}}</div>
      <div>{{> @computeLabel}}  {{> @computeSlider}}</div>
      <div>{{> @overageLabel}} {div#overage{> @overagePolicy}}</div>
    </div>
    {{> @limits}}
    <div>{{> @saveButton}} {{> @destroyButton}}</div>
    """

# class GroupsBundleLimitWrapper extends KDObject
#   constructor: (@limit, @usersLimit)->
#     super()
#     @calculate()
#     @limit.on 'update', @bound 'calculate'
#     @usersLimit.on 'update', @bound 'calculate'

#   calculate:->
#     {@unit, @title, @quota, @usage} = @limit
#     @perUserQuota = @quota / @usersLimit.quota
#     console.log this
#     @emit 'update'

class GroupsBundleLimitPerUserView extends JView

  pistachio: ->
    """
    {h2{#(title)}}
    {h3{#(usage)}}
    <h3>/</h3>
    <h3>{.per-user{#(perUserQuota)}} - {.total{#(quota)}}</h3>
    {h4{#(unit)}}
    """

class GroupsBundleLimitView extends JView

  pistachio: ->
    """
    {h2{#(title)}}
    {h3{#(usage)}}
    <h3>/</h3>
    {h3{#(quota)}}
    {h4{#(unit)}}
    """

class GroupsBundleView extends KDView

  resetBundleView: (bundle) ->

    @destroyChild 'createBundleView'
    @destroyChild 'editBundleView'
    @viewAppended()

  viewAppended: ->

    group = @getData()

    group.fetchBundle (err, bundle) =>
      return error err  if err?

      unless bundle?
        @createBundleView = new GroupsBundleCreateView {}, { group }
        @createBundleView.once 'BundleCreated', @bound 'resetBundleView'
        @addSubView @createBundleView
      else
        @editBundleView = new GroupsBundleEditView {}, { group, bundle }
        @editBundleView.once 'BundleDestroyed', @bound 'resetBundleView'
        @addSubView @editBundleView
