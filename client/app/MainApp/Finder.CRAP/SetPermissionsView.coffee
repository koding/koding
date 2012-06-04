class SetPermissionsView extends KDView
  constructor: ->
    super
    @switchers = {}
    
  decimalToAnother: (n, radix) ->
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
    @transponse s
    
  transponse: (s) ->
    n = s.length
    t = ''
    for i in [0...n]
      t = t + s.substring n - i - 1, n - i
    s = t
    s
    
  octalToBinary: (oc) ->
    binary = @decimalToAnother parseInt(oc, 8), 2
    for i in [binary.length...3] #normalizing to 3 bits
      binary = '0' + binary
    binary
    
  binaryToOctal: (bin) ->
    @decimalToAnother parseInt(bin, 2), 8
    
  createSwitchers: (name, permission = 6) ->
    @switchers[name] = []
    permissions = @octalToBinary permission
    for bit in permissions
      @switchers[name].push new KDRySwitch
        defaultValue : !!parseInt(bit)
        callback: =>
          @displayOctalPermissions()
    @switchers[name]
    
  getBinaryOfGroup: (group) ->
    binary = ''
    for switcher in @switchers[group]
      binary += if switcher.getValue() then '1' else 0
    binary
    
  getOctalPermissions: ->
    binaryOwner     = @getBinaryOfGroup 'owner'
    binaryGroup     = @getBinaryOfGroup 'group'
    binaryEveryone  = @getBinaryOfGroup 'everyone'
    
    owner     = @binaryToOctal(binaryOwner)
    group     = @binaryToOctal(binaryGroup)
    everyone  = @binaryToOctal(binaryEveryone)

    permissions = owner + group + everyone
    
  displayOctalPermissions: ->
    permissions = @getOctalPermissions()
    @footer.$('.newvalue').html permissions
    
  displayOldOctalPermissions: ->
    @footer.$('.oldvalue').html @getOptions().file.getData().mode
  
  viewAppended:->
    @applyExistingPermissions()
  
  applyExistingPermissions:()->
    setPermissionsView = @
    mode = @getOptions().file.getData().mode
    
    unless mode?
      @addSubView header = new KDCustomHTMLView 
        tagName : "header"
        cssClass : "clearfix"
        partial : "<div>Unknown file permissions</div>"
      
      @addSubView button = new KDButtonView 
        title : "Fetch file permissions"
        callback: ->
          setPermissionsView.getDelegate().fetch ->
            setPermissionsView.removeSubView header
            setPermissionsView.removeSubView button
            setPermissionsView.applyExistingPermissions()
      return
    
    permissions =
      owner: mode[0]
      group: mode[1]
      everyone: mode[2]
    
    @addSubView header = new KDCustomHTMLView 
      tagName : "header"
      cssClass : "clearfix"
      partial : "<span>Owner</span><span>Group</span><span>Everyone</span>"

    @addSubView sidebar = new KDCustomHTMLView
      tagName : "aside"
      cssClass : "permissions"
      partial : "<p>Read:</p><p>Write:</p><p>Execute:</p>"

    @addSubView switchHolder = new KDCustomHTMLView 
      tagName : "section"
      cssClass : "switch-holder clearfix"
      
    @addSubView @footer = new KDCustomHTMLView 
      tagName : "footer"
      cssClass : "clearfix"
      partial : "<p class='old'>Old: <em class='oldvalue'>655</em></p><p>New: <em class='newvalue'>655</em></p>"

    @footer.addSubView button = new KDButtonView 
      title : "Set"
      callback: =>
        @getDelegate().set @getOctalPermissions(), @recursive?.getValue() or no
        @displayOldOctalPermissions()
        
    if @getOptions().file.getData().type is 'folder'
      container = new KDView
      @recursive = new KDRySwitch
      container.addSubView new KDLabelView title: 'Apply to Enclosed Items'
      container.addSubView @recursive
      @footer.addSubView container, null, yes
      
    
    for name, permission of permissions
      switchers = @createSwitchers name, permission
      container = new KDView cssClass: 'switcher-group'
      for switcher in switchers
        container.addSubView switcher
      switchHolder.addSubView container
      
    setTimeout =>
      @displayOctalPermissions()
      @displayOldOctalPermissions()
    , 0
