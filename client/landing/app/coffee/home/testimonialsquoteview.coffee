JView            = require './../core/jview'

module.exports = class TestimonialsQuoteView extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}) ->
    options.tagName     = 'article'

    super options

  pistachio : ->
    {name, title, content} = @getOptions()

    slugifiedName = KD.utils.slugify name

    """
    <p>#{ content }</p>
    <div class='person'>
      <img src='/images/testimonials/#{ slugifiedName }.jpg'>
      <span class='name'>#{ name }</span>
      <span class='title'>#{ title }</span>
    </div>
    """



