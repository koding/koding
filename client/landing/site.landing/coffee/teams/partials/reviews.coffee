module.exports = class Reviews extends KDView

  IMAGEPATH = '/a/site.landing/images/teams/reviewers'
  ITEMS     = [
      {
        text: "
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc venenatis
          dui velit, a pretium velit volutpat vel.
          Donec lorem ante, hendrerit semper risus gravida, varius mattis diam.
          Praesent dui
        "
        who:
          name  : 'Sam Harris'
          title : 'SEO @koding.com'
          photo : 'sam_harris.jpg'
      }
      {
        text: "
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc venenatis
          dui velit, a pretium velit volutpat vel.
          Donec lorem ante, hendrerit semper risus gravida, varius mattis diam.
          Praesent dui
        "
        who:
          name  : 'Sam Harris'
          title : 'SEO @koding.com'
          photo : 'sam_harris.jpg'
      }
      {
        text: "
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc venenatis
          dui velit, a pretium velit volutpat vel.
          Donec lorem ante, hendrerit semper risus gravida, varius mattis diam.
          Praesent dui
        "
        who:
          name  : 'Sam Harris'
          title : 'SEO @koding.com'
          photo : 'sam_harris.jpg'
      }
    ]


  constructor: (options = {}, data) ->

    super options, data

    @setPartial @partial()

    @prepareReviews()


  prepareReviews: ->

    for item in ITEMS

      review = new KDCustomHTMLView
        tagName : 'li'
        partial : "
          <div class='review-content'>
            <div class='photo' style='background-image: url(#{IMAGEPATH}/#{item.who.photo})'></div>
            <p>#{ item.text }</p>
            <span class='who'>#{ item.who.name }</span>
            <span class='title'>#{ item.who.title }</span>
          </div>
        "

      @addSubView review, 'ul.reviews'


  partial: ->

    """
    <ul class='reviews'></ul>
    """


