class TestimonialsView extends KDView

  quotes = [
      name         : 'Lisha Sterling'
      title        : 'Teacher'
      content      : 'in my classes I have used Koding plenty of times. I love that you have virtual servers available on a web interface. So that in addition to writing code, we can all go into the same command line interface to experiment with things. Super useful.'
    ,
      name         : 'James Doyle'
      title        : 'Developer'
      content      : 'I wanted a place with free hosting and worked like a VPS. If you have something like GoDaddy, good luck installing a Rails or Node app.'
    ,
      name         : 'Jordan Cauley'
      title        : 'Front-end Engineer'
      content      : 'I started working as a freelancer, using Koding on and off. What I have in Koding right now is the start of my first web app, front-end and back-end running on Node.js.'
    ,
      name         : 'Heidi Dong'
      title        : 'Student'
      content      : 'I installed it on Koding and it worked from there. And since Koding had Git and stuff, it was great.  It was very helpful with that contest. I really love the community on Koding.'
    ,
      name         : 'Gemma Lynn'
      title        : 'Developer'
      content      : 'Yeah, and I also did a bunch of Coursera courses. There was an algorithms course, an R course, and a crypto course. And I was using Koding for all of that. It’s incredibly convenient.'
    ,
      name         : 'Eugene Esca'
      title        : 'Programmer'
      content      : 'Well, let’s say we have a client, who want to see your work live, in action. Just get them on Koding and ‘tada’, they’re watching you work.'
    ,
      name         : 'Cliff Rowley'
      title        : 'Developer'
      content      : "But what really sold Koding for me was the social element and the banter and most importantly, the KD framework. It’s genius. By offering the VM platform as a platform and allowing us to build apps around the KD framework is just a stroke of genius."
    ,
      name         : 'Aydincan Ataberk'
      title        : 'Entrepreneur'
      content      : "Koding’s community is actually the most important thing about Koding. You can get help, you feel like you’re in a family. It feels alive, to see the posts and feed."
    ,
      name         : 'Adem Aydin'
      title        : 'Student'
      content      : "recently I found a group of people on Koding who are interested in learning C. I thought C would be good to know for my field. So I found some pretty good people and in the next days we’ll start using Koding to collaborate on our learning."
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
      @innerContainer.addSubView @storiesButton = new CustomLinkView
        title       : 'Read more user stories'
        cssClass    : 'border-only-green'
        href        : 'http://stories.koding.com'
        target      : '_blank'
