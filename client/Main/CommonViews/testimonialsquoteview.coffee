class TestimonialsQuoteView extends KDCustomHTMLView
  constructor: (options = {}) ->
    options.tagName     = 'article'

    super options

  viewAppended : JView::viewAppended

  pistachio : ->
    {name, title, content} = @getOptions()

    slugifiedName = KD.utils.slugify name

    """
    <p>#{ content }</p>
    <div class='person'>
      <img src='/a/images/testimonials/#{ slugifiedName }.jpg'>
      <span class='name'>#{ name }</span>
      <span class='title'>#{ title }</span>
    </div>
    """



