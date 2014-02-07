class VMAlwaysOnToggleButtonView extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "vm-toggle-menu"
    super options, data
    @statusSwitch = new KDOnOffSwitch
      cssClass    : "tiny vm-toggle-item"
      callback    : @bound "toggle"

  toggle: (status) ->
    {vmName} = @getData()
    KD.remote.api.JVM.setAlwaysOn {vmName, status}, (err) =>
      if err
        KD.showError "You have exceeded your \"Always On\" VM quota"
        @decorate off

  decorate: (status) ->
    @statusSwitch.setValue status, no

  viewAppended: ->
    super
    {vmName} = @getData()
    KD.singleton("vmController").fetchVmInfo vmName, (err, info) =>
      @decorate info.alwaysOn

  pistachio: ->
    """<span>Always On</span> {{> @statusSwitch}}"""
