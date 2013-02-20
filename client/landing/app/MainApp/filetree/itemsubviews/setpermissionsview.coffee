###
  todo:
###

class NSetPermissionsView extends JView

  ###
  CLASS CONTEXT
  ###

  decimalToAnother = (n, radix) ->
    hex = []
    for i in [0..10]
      hex[i+1] = i
      
    s = ''
    a = n
    while a >= radix
      b = a % radix
      a = Math.floor a / radix
      s += hex[b + 1]
      
    s += hex[a + 1]
    transpose s
    
  transpose = (s) ->
    n = s.length
    t = ''
    for i in [0...n]
      t = t + s.substring n - i - 1, n - i
    s = t
    s
    
  octalToBinary = (oc) ->
    binary = decimalToAnother parseInt(oc, 8), 2
    for i in [binary.length...3] #normalizing to 3 bits
      binary = '0' + binary
    binary
    
  binaryToOctal = (bin) ->
    decimalToAnother parseInt(bin, 2), 8


  ###
  INSTANCE METHODS
  ###

  constructor: ->
    
    super

    @switches = {}

    @fetchPermissionsButton = new KDButtonView 
      title : "Fetch file permissions"
      callback: ->
        log "fetch"
        # setPermissionsView.getDelegate().fetch ->
        #   setPermissionsView.removeSubView header
        #   setPermissionsView.removeSubView button
        #   setPermissionsView.applyExistingPermissions()

    @recursive = new KDOnOffSwitch

    @loadingMask = new KDView
      cssClass: "switcher-group-mask"

    @loadingMask.hide()

  setPermission: (permission, callback) ->
    @loadingMask.show() 
    permissions = permission ? @getOctalPermissions()
    recursive   = @recursive.getValue() or no
    file        = @getData()
    file.chmod {permissions, recursive}, (err,res)=>
      unless err
        @loadingMask.hide()
        callback?()
    
  createSwitches: (name, permission = 6) ->
    @switches[name] = []
    permissions = octalToBinary permission
    for bit in permissions
      @switches[name].push new KDOnOffSwitch
        defaultValue  : !!parseInt(bit)
        callback      : =>
          @displayOctalPermissions()
          @setPermission()
    @switches[name]

  getBinaryOfGroup: (group) ->
    binary = ''
    for switcher in @switches[group]
      binary += if switcher.getValue() then '1' else 0
    binary
    
  getOctalPermissions: ->
    binaryOwner     = @getBinaryOfGroup 'owner'
    binaryGroup     = @getBinaryOfGroup 'group'
    binaryEveryone  = @getBinaryOfGroup 'everyone'
    
    owner     = binaryToOctal(binaryOwner)
    group     = binaryToOctal(binaryGroup)
    everyone  = binaryToOctal(binaryEveryone)

    permissions = owner + group + everyone
    
  displayOctalPermissions: ->
    @newModeInput.setValue @getOctalPermissions()
    
  canSetRecursively: ->
    return @getData().type in ['folder', 'multiple']

  viewAppended:->
    @setClass "set-permissions-wrapper"
    @applyExistingPermissions()
    super
    @createModeInput()
    if @canSetRecursively()
      @$('.recursive').removeClass "hidden" 
      @loadingMask.setClass "can-set-recursive"

  createModeInput: ->
    @addSubView @newModeLabel = new KDLabelView 
      cssClass : "new-mode-label"
      title    : "New"
      
    @addSubView @newModeInput = new KDInputView
      cssClass : "new-mode-input"
      validate      :
        event       : "keyup"
        rules       :
          required  : yes
          maxLength : 3
        messages    :
          required  : "File permission mode required"
          maxLength : "New file permission mode must be 3 chars"
      keyup         : =>
        value = Encoder.XSSEncode @newModeInput.getValue()
        if value > 99 and value < 778
          @setPermission value, =>
            data = @getData()
            data.mode    = value
            data.newMode = value
            @setData data
            @destroySubViews()
            @viewAppended()

  pistachio:->
    mode = @getData().mode
    
    unless mode?
      """
      <header class="clearfix"><div>Unknown file permissions</div></header>
      {{> @fetchPermissionsButton}}
      """
    else
      """
      <header class="clearfix"><span>Owner</span><span>Group</span><span>Everyone</span></header>
      <aside class="permissions"><p>Read:</p><p>Write:</p><p>Execute:</p></aside> 
      <section class="switch-holder clearfix">
        <div class="kdview switcher-group">
          {{> @switches.owner[0]}}
          {{> @switches.owner[1]}}
          {{> @switches.owner[2]}}
        </div>
        <div class="kdview switcher-group">
          {{> @switches.group[0]}}
          {{> @switches.group[1]}}
          {{> @switches.group[2]}}
        </div>
        <div class="kdview switcher-group">
          {{> @switches.everyone[0]}}
          {{> @switches.everyone[1]}}
          {{> @switches.everyone[2]}}
        </div>
        {{> @loadingMask}}
      </section>
      <footer class="clearfix">
        <div class="recursive hidden">
          <label>Apply to Enclosed Items</label>
          {{> @recursive}}
        </div>
      </footer>
      """
      
  
  applyExistingPermissions:()->
    
    setPermissionsView = @
    {mode} = @getData()
    
    @getData().newMode = mode
    
    permissions =
      owner     : mode[0]
      group     : mode[1]
      everyone  : mode[2]
    
    @createSwitches name, permission for name, permission of permissions

    setTimeout =>
      @displayOctalPermissions()
    , 0
