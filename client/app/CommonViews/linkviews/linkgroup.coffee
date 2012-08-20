class LinkGroup extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName         = 'div'
    options.cssClass        = 'link-group'
    options.subItemClass  or= ProfileLinkView
    options.itemsToShow   or= 3
    options.totalCount    or= data?.length or options.group?.length or 0
    options.hasMore         = options.totalCount > options.itemsToShow

    super options, data

    if data?
      @createParticipantSubviews()
    else if options.group
      @loadFromOrigins options.group

  loadFromOrigins:(group)->

    callback = (data)=>
      @setData data
      @createParticipantSubviews()
      @render()

    if group[0]?.constructorName
      lastFour = group.slice -4
      bongo.cacheable lastFour, (err, bucketContents)=>
        callback bucketContents
    else
      callback group

  itemClass:(options, data)->
    new (@getOptions().subItemClass) options, data

  createParticipantSubviews:->
    participants = @getData()
    for participant, index in participants
      @["participant#{index}"] = @itemClass {}, participant
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    # log "in pistachio again",">>>>>>>>>>>>>>"
    participants = @getData()
    {hasMore, totalCount, group} = @getOptions()

    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        new FollowedModalView {group}, @getData()

    sep = ' '
    if participants[0] instanceof bongo.api.JAccount
      sep = ', '
    switch totalCount
      when 0 then ""
      when 1 then "{{> @participant0}}"
      when 2 then "{{> @participant0}} and {{> @participant1}}"
      when 3 then "{{> @participant0}}#{sep}{{> @participant1}} and {{> @participant2}}"
      when 4 then "{{> @participant0}}#{sep}{{> @participant1}}#{sep}{{> @participant2}} and {{> @participant3}}"
      else "{{> @participant0}}#{sep}{{> @participant1}}#{sep}{{> @participant2}} and {{> @more}}"

  render:->
    # log "rendering",">>>>>>>>>>>>>>"
    @createParticipantSubviews()
