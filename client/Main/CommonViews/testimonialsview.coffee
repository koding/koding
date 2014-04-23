class TestimonialsView extends KDView

  quotes = [
      name         : 'Lisha Sterling'
      title        : 'Teacher'
      content      : 'She’s uses Koding in her programming classes to ensure
                      that her beginner students can work simply on
                      understanding/writing code.'
    ,
      name         : 'James Doyle'
      title        : 'Developer'
      content      : 'I wanted a place with free hosting and worked like a VPS.
                      If you have something like GoDaddy, good luck installing a
                      Rails or Node app.'
    ,
      name         : 'Jordan Cauley'
      title        : 'Front-end Engineer'
      content      : 'In the last year and a half, he’s used Koding to go
                      from being a basic WordPress theme editor to a full
                      on front-end engineer.'
    ,
      name         : 'Heidi Dong'
      title        : 'Student'
      content      : 'I used to play around with WordPress there. I really
                      love how the Koding terminal has everything on it. So
                      I learned a lot of commands on there.'
    ,
      name         : 'Gemma Lynn'
      title        : 'Developer'
      content      : 'She uses Koding for learning new languages, frameworks,
                      and completing Coursera classes.'
    ,
      name         : 'Eugene Esca'
      title        : 'Programmer'
      content      : 'He loves interact with the Koding community and uses
                      Koding both for client work and tinkering with friends.'
    ,
      name         : 'Cliff Rowley'
      title        : 'Developer'
      content      : "He's addicted to learning new programming languages and
                      is excited to build apps on Koding platform."
    ,
      name         : 'Aydincan Ataberk'
      title        : 'Entrepreneur'
      content      : "Koding has helped him learn Python which he’ll ultimately
                      use to build apps and games."
    ,
      name         : 'Adem Aydin'
      title        : 'Student'
      content      : "He uses Koding for getting feedback on small things he’s
                      built and recently set up a group on Koding to learn C
                      together."
    ,
    ]

  constructor : (options = {}) ->

    options.cssClass          = KD.utils.curry "testimonials", options.cssClass
    options.tagName         or= 'section'
    options.quotesCount     or= 2
    options.showMoreButton   ?= yes

    super options


  createQuotes : ->
    randomIndexes = []

    while randomIndexes.length < @getOption 'quotesCount'

      index = Math.floor Math.random()*quotes.length

      if (randomIndexes.indexOf index) is -1

        randomIndexes.push index

        @innerContainer.addSubView new TestimonialsQuoteView quotes[index]


  viewAppended : ->

    @addSubView @innerContainer = new KDCustomHTMLView
      cssClass : 'inner-container clearfix'

    @innerContainer.addSubView new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'general-title'
      partial  : 'What did they say'

    @innerContainer.addSubView new KDCustomHTMLView
      tagName  : 'h4'
      cssClass : 'general-subtitle'
      partial  : 'People love Koding for a reason. Guess what that reason is?'

    @createQuotes()

    if @getOption 'showMoreButton'
      @innerContainer.addSubView @storiesButton = new KDButtonView
        title       : 'Read more user stories'
        style       : 'solid green medium border-only'
        callback    : ->
          window.location.href = 'http://stories.koding.com'




