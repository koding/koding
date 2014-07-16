class GroupDescription extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName or= 'section'

    super options, data

    {groupsController} = KD.singletons

    groupsController.ready =>

      group = groupsController.getCurrentGroup()

      {body}  = group
      body   ?= ""
      hasBody = Boolean body.trim().length
      isAdmin = "admin" in KD.config.roles

      # edit = new CustomLinkView
      #   title    : "Group settings"
      #   cssClass : if isAdmin then "show-all-link" else "show-all-link hidden"
      #   click    : (event)->
      #     KD.utils.stopDOMEvent event
      #     KD.singletons.router.handleRoute "/Dashboard"  if isAdmin

      @titleView = new JCustomHTMLView
        tagName         : "h3"
        # pistachioParams : { edit }
        # pistachio       : "{{ #(title)}} {{> edit}}"
        pistachio       : "{{ #(title) }}"
      , group

      # @bodyView = new JCustomHTMLView
      #   tagName   : "p"
      #   pistachio : "{{ #(body) or ''}}"
      #   cssClass  : "group-description"
      # , group

      @addSubView @titleView
      # @addSubView @bodyView

      if "admin" in KD.config.roles
        @bodyView.setPartial "You can have a short description for your group here"  unless hasBody

