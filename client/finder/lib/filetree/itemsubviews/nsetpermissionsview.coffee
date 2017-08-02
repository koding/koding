kd = require 'kd'
KDButtonView = kd.ButtonView
KodingSwitch = require 'app/commonviews/kodingswitch'

module.exports = class NSetPermissionsView extends kd.View

  constructor: ->

    super

    @switches = []

    @setPermissionsButton = new KDButtonView
      title     : 'Set'
      style     : 'solid green small'
      callback  : =>
        permissions = @getPermissions()
        recursive   = @recursive.getValue() or no
        file        = @getData()
        file.chmod { permissions, recursive }, (err, res) =>
          unless err
            @displayOldOctalPermissions()

    @recursive = new KodingSwitch
      size : 'tiny'

  permissionsToOctalString = (permissions) ->
    str = permissions.toString 8
    str = '0' + str while str.length < 3
    return str[-3..]

  createSwitches: (permission) ->
    for i in [0...9]
      @switches.push new KodingSwitch
        size          : 'tiny'
        defaultValue  : (permission & (1<<i)) isnt 0
        callback      : (state) =>
          @displayOctalPermissions()

  getPermissions: ->
    permissions = 0
    for s, i in @switches
      permissions |= 1<<i if s.getValue()
    return permissions

  displayOctalPermissions: ->
    @$('footer p.new em').html permissionsToOctalString(@getPermissions())

  displayOldOctalPermissions: ->
    @$('footer p.old em').html permissionsToOctalString(@getData().mode)

  viewAppended: ->
    @setClass 'set-permissions-wrapper'
    @applyExistingPermissions()
    super
    @$('.recursive').removeClass 'hidden' if @getData().type in ['folder', 'multiple']

  pistachio: ->
    mode = @getData().mode

    unless mode?
      '''
      <header class="clearfix"><div>Unknown file permissions</div></header>
      '''
    else
      '''
      <header class="clearfix"><span>Read</span><span>Write</span><span>Execute</span></header>
      <aside class="permissions"><p>Owner:</p><p>Group:</p><p>Everyone:</p></aside>
      <section class="switch-holder clearfix">
        <div class="kdview switcher-group">
          {{> @switches[8]}}
          {{> @switches[5]}}
          {{> @switches[2]}}
        </div>
        <div class="kdview switcher-group">
          {{> @switches[7]}}
          {{> @switches[4]}}
          {{> @switches[1]}}
        </div>
        <div class="kdview switcher-group">
          {{> @switches[6]}}
          {{> @switches[3]}}
          {{> @switches[0]}}
        </div>
      </section>
      <footer class="clearfix">
        <div class="recursive hidden">
          <label>Apply to Enclosed Items</label>
          {{> @recursive}}
        </div>
        <p class="old">Old: <em></em></p>
        <p class="new">New: <em></em></p>
        {{> @setPermissionsButton}}
      </footer>
      '''

  applyExistingPermissions: ->

    setPermissionsView = this
    { mode } = @getData()

    @getData().newMode = mode
    @createSwitches mode

    setTimeout =>
      @displayOctalPermissions()
      @displayOldOctalPermissions()
    , 0
