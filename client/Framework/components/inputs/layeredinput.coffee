class KDLayeredInput extends JView

  constructor:(options = {}, data)->

    options.cssClass   = "kdlayeredinput#{if options.cssClass then ' '+options.cssClass else ''}"
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
    @calc  = new KDCustomHTMLView cssClass : 'layer calculation'

    @input.unsetClass 'kdinput'

    # @input.on "change", =>
    #   log "any news on change"
    #   @layer.updatePartial @input.getValue()

    @input.on "keyup", (event)=>
      val = @input.getValue().replace /\n/g,'<br/>'
      @calc.updatePartial val
      matches = val.match /\s*#\w\w+/g
      log match
      @layer.updatePartial val



  pistachio:->

    """
    <div class='kdlayeredinput-inner-wrapper'>
      {{> @layer}}
      {{> @calc}}
      {{> @input}}
    </div>
    """