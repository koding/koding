class KDTokenizedInput extends JView

  constructor:(options = {}, data)->

    options.cssClass   = "kdtokenizedinput#{if options.cssClass then ' '+options.cssClass else ''}"
    options.match    or= null    # an Object of matching rules
    options.input    or= {}      # an Object of KDInputView options
    options.layer    or= {}      # an Object of KDView options

    super options, data

    o = @getOptions()

    o.input.type     or= "textarea"
    o.input.bind     or= "change"
    o.input.cssClass or= "input layer#{if o.input.cssClass then ' '+o.input.cssClass else ''}"
    o.layer.cssClass or= "presentation layer#{if o.layer.cssClass then ' '+o.layer.cssClass else ''}"

    @input = new KDInputView o.input
    @layer = new KDCustomHTMLView o.layer
    @menu  = null

    @input.unsetClass 'kdinput'

    @registeredTokens = {}
    @_oldMatches      = []

    for own rule of o.match
      @registeredTokens[rule] = []

    @input.on "keydown", @keyDownOnInput.bind @
    @input.on "keyup", @keyUpOnInput.bind @

  keyDownOnInput:(event)->
    @decorateLayer()

  keyUpOnInput:(event)->
    {_oldMatches} = @
    matchRules = @getOptions().match
    val = @input.getValue()
    @decorateLayer()
    {input} = @

    # log "Caret Pos:", input.getCaretPosition()

    if matchRules
      for own rule, ruleSet of matchRules
        val = val.slice(0, input.getCaretPosition())
        matches = val.match ruleSet.regex
        if matches
          matches.forEach (match,i)->
            unless _oldMatches[i] is match
              _oldMatches[i] = match
              if ruleSet.throttle
                do _.throttle ->
                  ruleSet.dataSource match
                , ruleSet.throttle
              else
                ruleSet.dataSource match

  showMenu:(options, data)->

    {token, rule} = options
    @menu.destroy() if @menu
    o =
      x                 : @getX()
      y                 : @input.getY() + @input.getHeight()
      itemChildClass    : options.itemChildClass
      itemChildOptions  : options.itemChildOptions
      treeItemClass     : options.treeItemClass
      listViewClass     : options.listViewClass
      addListsCollapsed : options.addListsCollapsed
      putDepthInfo      : options.putDepthInfo

    # log o

    @input.setBlur()
    @menu = new KDTokenizedMenu o, data
    @menu.on "ContextMenuItemReceivedClick", (menuItem)=>
      @registerSelectedToken {rule, token}, menuItem.getData()

  registerSelectedToken:({rule, token}, data)->

    replacedText = @parseReplacer rule, data

    dataSet = {replacedText, data, token}
    @registeredTokens[rule].push dataSet

    val = @input.getValue()
    val = val.replace token, replacedText
    @input.setValue val
    @menu.destroy()
    @utils.defer =>
      @input.setFocus()
      @input.setCaretPosition val.indexOf(replacedText) + replacedText.length
      @decorateLayer()
      @getOptions().match[rule].added? data

  decorateLayer:(event)->

    value  = @input.getValue()

    $layer = @layer.$()
    $input = @input.$()
    $layer.text value
    replacedTextHash = {}

    # log "VALUE", value

    cp     = @input.getCaretPosition()
    caret  = "<span class='caret'></span>"
    inner  = $layer.html()
    inner  = inner[...cp] + caret + inner[cp...]

    $layer.scrollTop $input.scrollTop()
    for own rule, tokens of @registeredTokens
      for dataSet in tokens
        replacedTextHash[dataSet.replacedText] = dataSet
        replacedTextHash[dataSet.replacedText].rule = rule
        inner = inner.replace dataSet.replacedText, "<b#{if c = @getOptions().match[rule].wrapperClass then ' class=\"'+c+'\"' else ''}>#{dataSet.replacedText}</b>"

    $layer.html inner

    for own replacedText, dataSet of replacedTextHash
      if @input.getValue().indexOf(replacedText) is -1
        @getOptions().match[dataSet.rule].removed? dataSet.data
        for tokenSet,i in @registeredTokens[dataSet.rule]
          if tokenSet.replacedText is replacedText
            @registeredTokens[dataSet.rule].splice i, 1
            log "remove token"
            break

  parseReplacer:(rule, data)->

    tmpl = @getOptions().match[rule].replaceSignature or "{{#(title)}}"
    arr  = tmpl.match /\{\{#\([\w|\.]+\)\}\}/g
    hash = {}

    for match in arr
      path = match.replace('{{#(', '').replace(')}}','')
      hash[match] = JsPath.getAt data, path

    for own mustache, value of hash
      tmpl = tmpl.replace mustache, value

    return tmpl


  pistachio:->

    """
    <div class='kdtokenizedinput-inner-wrapper'>
      {{> @layer}}
      {{> @input}}
    </div>
    """

# Example

# addSubView button = new BottomChatRoom

# class BottomChatRoom extends JView
#   constructor:->
#     super
#     @tokenInput = tokenInput = new KDTokenizedInput
#       cssClass             : 'chat-input'
#       input                :
#         keydown            :
#           "alt super+right"   : (e)->
#             tokenInput.emit "chat.ui.splitPanel", e.which
#             e.preventDefault()
#           "alt alt+right"     : (e)->
#             tokenInput.emit "chat.ui.focusNextPanel"
#           "alt alt+left"      : (e)->
#             tokenInput.emit "chat.ui.focusPrevPanel"
#           "alt alt+backspace" : (e)->
#             tokenInput.emit "chat.ui.focusPrevPanel"
#       match                :
#         topic              :
#           regex            : /\B#\w.*/
#           # throttle         : 2000
#           wrapperClass     : "highlight-tag"
#           replaceSignature : "{{#(title)}}"
#           added            : (data)->
#             log "tag is added to the input", data
#           removed          : (data)->
#             log "tag is removed from the input", data
#           dataSource       : (token)->
#             appManager.tell "Topics", "fetchSomeTopics", selector : token.slice(1), (err, topics)->
#               # log err, topics
#               if not err and topics.length > 0
#                 tokenInput.showMenu {token, rule : "topic"}, topics
#         username           :
#           regex            : /\B@\w.+/
#           wrapperClass     : "highlight-user"
#           replaceSignature : "{{#(profile.firstName)}} {{#(profile.lastName)}}"
#           added            : (data)->
#             log "user is added to the input", data
#           removed          : (data)->
#             log "user is removed from the input", data
#           dataSource       : (token)->
#             # log token, "member"
#             appManager.tell "Members", "fetchSomeMembers", selector : token.slice(1), (err, members)->
#               # log err, members
#               if not err and members.length > 0
#                 tokenInput.showMenu {
#                   rule             : "username"
#                   itemChildClass   : MembersListItemView
#                   itemChildOptions :
#                     cssClass       : "honolulu"
#                     userInput      : token.slice(1)
#                   token
#                 }, members
#
#     @outputController = new KDListViewController
#     @output = @outputController.getView()
#     @sidebar = new KDView
#       cssClass : "room-sidebar"
#
#   pistachio:->
#     """
#       <section>
#         {{> @output}}
#         {{> @tokenInput}}
#       </section>
#       {{> @sidebar}}
#     """
