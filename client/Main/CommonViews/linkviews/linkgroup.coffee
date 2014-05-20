class LinkGroup extends KDCustomHTMLView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.tagName         = 'div'
    options.cssClass        = 'link-group'
    options.itemClass     or= ProfileLinkView
    options.itemOptions   or= {}
    options.itemsToShow   or= 3
    options.totalCount    or= data?.length or options.group?.length or 0
    options.hasMore         = options.totalCount > options.itemsToShow
    options.separator      ?= ', '
    options.suffix        or= ''

    super options, data

    if @getData()
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
        if err
        then warn err
        else callback bucketContents
    else
      callback group

  createParticipantSubviews:->
    {itemClass, itemOptions} = @getOptions()
    participants = @getData()

    # unless participants
    #   debugger
    #   return

    for participant, index in participants when participant
      if participant?.bongo_?.constructorName is "ObjectRef"
        itemOptions.origin = participant
        @["participant#{index}"] = new itemClass itemOptions
      else
        @["participant#{index}"] = new itemClass itemOptions, participant

    # tmp fix
    return unless @participant0

    @setTemplate @pistachio()
    @template.update()

  viewAppended: -> super()

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
        new ShowMoreDataModalView {group}, @getData()

  pistachio:->
    {suffix, hasMore, totalCount, group, separator} = @getOptions()

    @createMoreLink()
    # fix for old cache instances
    count = totalCount
    count = 1e3 if count is 4 and not @participant3
    switch count
      when 0 then ""
      when 1 then "{{> @participant0}}#{suffix}"
      when 2 then "{{> @participant0}} and {{> @participant1}}#{suffix}"
      when 3 then "{{> @participant0}}#{separator}{{> @participant1}} and {{> @participant2}}#{suffix}"
      when 4 then "{{> @participant0}}#{separator}{{> @participant1}}#{separator}{{> @participant2}} and {{> @participant3}}#{suffix}"
      else "{{> @participant0}}#{separator}{{> @participant1}}#{separator}{{> @participant2}} and {{> @more}}#{suffix}"

  render:->

    @createParticipantSubviews()
