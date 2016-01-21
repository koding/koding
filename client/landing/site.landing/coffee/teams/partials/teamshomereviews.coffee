module.exports = class TeamsHomeReviews extends KDView

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

    options.tagName  = 'ul'
    options.cssClass = 'reviews'

    super options, data

    @prepareReviews()


  prepareReviews: ->

    reviews = ''

    for item in ITEMS

      reviews += """
        <li>
          <div class='review-content'>
            <div class='photo' style='background-image: url(#{IMAGEPATH}/#{item.who.photo})'></div>
            <p>#{ item.text }</p>
            <span class='who'>#{ item.who.name }</span>
            <span class='title'>#{ item.who.title }</span>
          </div>
          </li>
        """

    @setPartial reviews
