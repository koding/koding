class LinkGroup extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName         = 'div'
    options.cssClass        = 'link-group'
    options.itemClass     or= ProfileLinkView
    options.itemOptions   or= {}
    options.itemsToShow   or= 3
    options.totalCount    or= data?.length or options.group?.length or 0
    options.hasMore         = options.totalCount > options.itemsToShow
    options.separator      ?= ', '

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
      KD.remote.cacheable lastFour, (err, bucketContents)=>
        callback bucketContents
    else
      callback group

  createParticipantSubviews:->
    {itemClass, itemOptions} = @getOptions()
    participants = @getData()
    for participant, index in participants
      if participant.bongo_.constructorName is "ObjectRef"
        itemOptions.origin = participant
        @["participant#{index}"] = new itemClass itemOptions
      else
        @["participant#{index}"] = new itemClass itemOptions, participant
    @setTemplate @pistachio()
    @template.update()

  createMoreLink:->

    @more.destroy() if @more
    {totalCount, group} = @getOptions()
    @more = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "more"
      partial     : "#{totalCount-3} more"
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        new FollowedModalView {group}, @getData()

  pistachio:->

    participants = @getData()
    {hasMore, totalCount, group, separator} = @getOptions()

    @createMoreLink()

    switch totalCount
      when 0 then ""
      when 1 then "{{> @participant0}}"
      when 2 then "{{> @participant0}} and {{> @participant1}}"
      when 3 then "{{> @participant0}}#{separator}{{> @participant1}} and {{> @participant2}}"
      when 4 then "{{> @participant0}}#{separator}{{> @participant1}}#{separator}{{> @participant2}} and {{> @participant3}}"
      else "{{> @participant0}}#{separator}{{> @participant1}}#{separator}{{> @participant2}} and {{> @more}}"

  render:->

    @createParticipantSubviews()
