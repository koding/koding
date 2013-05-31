class IntroductionItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = options.cssClass or "admin-introduction-item"

    super options, data

    @createElements()

  createElements: ->
    data = @getData()

    @title = new KDView
      cssClass : "cell name"
      partial  : data.title
      click    : => @setupChilds()

    @title.addSubView @arrow = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "arrow"

    @addLink = new KDCustomHTMLView
      tagName  : "span"
      partial  : "<span class='icon add'></span>"
      click    : => @add()
      tooltip  :
        title  : "Add Into"

    @updateLink = new KDCustomHTMLView
      tagName  : "span"
      partial  : "<span class='icon update'></span>"
      click    : => @update()
      tooltip  :
        title  : "Update"

    @deleteLink = new KDCustomHTMLView
      tagName  : "span"
      partial  : "<span class='icon delete'></span>"
      click    : => @remove()
      tooltip  :
        title  : "Delete"

  add: ->
    @getDelegate().showForm "Item", @getData()

  update: ->
    @getDelegate().showForm "Group", @getData(), "Update"

  remove: ->
    @getData().delete => @destroy()
    @getDelegate().emit "IntroductionItemDeleted", @getData()

  setupChilds: ->
    if @childContainer
      if @isChildContainerVisible
        @childContainer.hide()
        @arrow.unsetClass "down"
        return @isChildContainerVisible = no
      else
        @childContainer.show()
        @arrow.setClass "down"
        return @isChildContainerVisible = yes
    else
      @addSubView @childContainer = new KDView
      @isChildContainerVisible = yes
      @arrow.setClass "down"

      for snippet in @getData().snippets
        @childContainer.addSubView new IntroductionChildItem delegate: @, snippet

  isExpired: (expiryDate) ->
    return new Date(expiryDate).getTime() < @getDelegate().currentTimestamp

  pistachio: ->
    data       = @getData()
    hasOverlay = if data.overlay is "yes" then "yep" else "nope"
    status     = if @isExpired(data.expiryDate) is yes then "nope" else "yep"
    visibility = if data.visibility is "allTogether" then "allTogether" else "stepByStep"

    """
      {{> @title}}
      <div class="cell mini">#{data.snippets.length}</div>
      <div class="cell icon #{status}"></div>
      <div class="cell icon #{hasOverlay}"></div>
      <div class="cell icon #{visibility}"></div>
      <div class="introduction-actions cell">
        {{> @addLink}}{{> @updateLink}}{{> @deleteLink}}
      </div>
    """
