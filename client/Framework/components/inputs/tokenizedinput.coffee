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

    _oldMatches = []
    @input.on "keydown", (event)=>
      val = @input.getValue().replace /\n/g,'<br/>'
      @layer.updatePartial val

    @input.on "keyup", (event)=>
      matchRules = @getOptions().match
      val = @input.getValue()
      if matchRules
        for rule, ruleSet of matchRules
          matches = val.match ruleSet.regex
          
          return unless matches

          matches.forEach (match,i)->
            log match,_oldMatches[i],i
            return if _oldMatches[i] is match
            _oldMatches[i] = match

            if ruleSet.throttle
              do _.throttle ->
                ruleSet.dataSource match
              , ruleSet.throttle
            else
              ruleSet.dataSource match

  showMenu:(options, data)->
    
    {token,rule} = options
    @menu.destroy() if @menu
    o =
      x : @getX()
      y : @input.getY() + @input.getHeight()
    @input.setBlur()
    @menu = new JContextMenu o, data
    @menu.on "ContextMenuItemReceivedClick", (menuItem)=>
      @getOptions().match[rule].callback token, menuItem.getData()

  pistachio:->

    """
    <div class='kdtokenizedinput-inner-wrapper'>
      {{> @layer}}
      {{> @input}}
    </div>
    """