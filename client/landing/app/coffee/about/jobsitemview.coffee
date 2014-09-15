module.exports = class JobsItemView extends JView
  constructor : (options = {}, data) ->

    options.cssClass = KD.utils.curry 'jobs-item-view', options.cssClass

    super options, data

    @detailsShown = no

    @readMore    = new CustomLinkView
      cssClass   : 'read-more-link'
      title      : 'Read More'
      click      : @bound 'toggleDetails'

    @applyButton = new CustomLinkView
      title      : 'APPLY FOR THIS JOB'
      cssClass   : 'apply-button'
      href       : @getData().applyUrl

  toggleDetails : (e) ->

    e.preventDefault()

    @detailsShown = !@detailsShown

    if @detailsShown
      @setClass 'show-details'
      @readMore.updatePartial 'Hide Details'

    else
      @unsetClass 'show-details'
      @readMore.updatePartial 'Read More'

  getHeadingView : ->

    {text, categories} = @getData()

    heading = new KDCustomHTMLView
      tagName     : 'h3'
      partial     : text
      click       : @bound 'toggleDetails'


    heading.addSubView new KDCustomHTMLView
      tagName   : 'span'
      partial   : categories.commitment
      cssClass  : "commitment #{KD.utils.slugify categories.commitment}"

    heading.addSubView new KDCustomHTMLView
      tagName   : 'span'
      partial   : categories.location
      cssClass  : "location #{KD.utils.slugify categories.location}"

    heading.addSubView new KDCustomHTMLView
      tagName   : 'span'
      partial   : categories.team
      cssClass  : "team #{KD.utils.slugify categories.team}"

    return heading

  getDetailsView : ->

    {lists, applyUrl, description, additional} = @getData()

    paragraphs = (description.split '\n').splice 1
    additionalParagraphs = additional.split '\n'

    details = new KDCustomHTMLView
      tagName     : 'article'
      cssClass    : 'details'

    for content in paragraphs
      if content
        details.addSubView new KDCustomHTMLView
          tagName : 'p'
          partial : content

    for list in lists
      details.addSubView new KDCustomHTMLView
        tagName   : 'h5'
        partial   : list.text

      details.addSubView new KDCustomHTMLView
        tagName   : 'ul'
        partial   : list.content

    for content in additionalParagraphs
      if content
        details.addSubView new KDCustomHTMLView
          tagName : 'p'
          partial : content

    details.addSubView new CustomLinkView
      title      : 'APPLY FOR THIS JOB'
      cssClass   : 'apply-button border-only'
      href       : @getData().applyUrl

    return details

  pistachio : ->

    {description} = @getData()
    summary       = description.split('\n', 1)[0]

    """
    {{> @getHeadingView() }}
    {{> @applyButton }}
    <p class='summary'>
      #{summary} {{> @readMore }}
    </p>
    {{> @getDetailsView() }}
    """
