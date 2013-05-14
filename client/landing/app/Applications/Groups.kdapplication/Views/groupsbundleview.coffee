class GroupsBundleCreateView extends JView

  constructor:(options, data)->
    super

    group = @getData()

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

  constructor: (options, data) ->
    super

    group = @getData()

    @destroyButton = new KDButtonView
      style     : "clean-gray"
      title     : "Destroy bundle"
      callback  : =>
        group.destroyBundle (err, bundle) =>
          return error err  if err?

          @emit 'BundleDestroyed', bundle

  pistachio:->
    """
    <h3>Bundle details</h3>
    <p>There will be some cool details here.</p>
    <p>For now you can only destroy it.</p>
    {{> @destroyButton}}
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
        @createBundleView = new GroupsBundleCreateView {}, group
        @createBundleView.once 'BundleCreated', @bound 'resetBundleView'
        @addSubView @createBundleView
      else
        @editBundleView = new GroupsBundleEditView {}, group
        @editBundleView.once 'BundleDestroyed', @bound 'resetBundleView'
        @addSubView @editBundleView
