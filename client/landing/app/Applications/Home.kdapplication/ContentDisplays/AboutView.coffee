class AboutView extends KDScrollView
  constructor:->
    super
    
  viewAppended:->
    super
    @addSubView @leftSide = new KDView
      cssClass : "about-page-left"

    @addSubView @rightSide = new KDView 
      cssClass : "about-page-right"

    @putIntro()
    @putHow()
    @putBarriers()
    @putBetterPlace()
    @putFree()
    @putLocation()
    @putTeam()

  putIntro:->
    @leftSide.addSubView header = new KDView
      tagName     : 'h2'
      partial     : 'About Koding'

    @leftSide.addSubView subhead = new KDView
      tagName     : 'p'
      cssClass    : 'about-sub'
      partial     : 'Koding is a developer community and cloud development environment where developers come together and code – in the browser&hellip; with a real development server to run their code.'

    @leftSide.addSubView introPara = new KDView
      tagName     : 'p'
      partial     : "We&rsquo;ve created a platform for developers where getting started is easy. Developers can work, collaborate, write and run apps without jumping through hoops and spending hard earned money."

  putHow:->
    @leftSide.addSubView header = new KDView
      tagName     : 'h3'
      partial     : 'How We Started'

    @leftSide.addSubView paraOne = new KDView
      tagName     : 'p'
      partial     : "Koding started with two brothers&hellip; Myself (Devrim) & Sinan coming together to give something back to the developer community."

    @leftSide.addSubView paraTwo = new KDView
      tagName     : 'p'
      partial     : "How did it start? Well, in the summer of 2008&mdash;7 years later than the last time we had developed a website&mdash;I just wanted to make a website and learn PHP at the same time&hellip; maybe install WordPress and do a blog. I hoped that things would be much faster and smarter than it was 7 years before. Once I got started, I quickly realized that not much had changed."

  putBarriers:->
    @leftSide.addSubView header = new KDView
      tagName     : 'h3'
      partial     : 'Barriers To Entry AKA <span>Developer Hell</span>'

    @leftSide.addSubView paraOne = new KDView
      tagName     : 'p'
      partial     : "I had to download the zip, I had to unzip it, (it was even more fun with tar.gz). I had to have FTP running on the server and an FTP client on my local computer, I had to upload those files after I changed config.inc, I had to have the correct database setup and wait until I got everything uploaded (waiting for FTP to finish a thousand files was the best time to meditate), not to mention, user permissions, apache settings, SVN setup, dealing with hosting companies, going through all sorts of nonsese... and worst of all, at every turn being asked for money. Need hosting? BUY NOW! $2 for crappy shared hosting, $50 for a less crappy VPS, Not enough? pay $100 for a dedicated server, learn to be a sys admin and dedicate yourself to those sort of problems problems. Call support if your dedication isn’t enough and pay little more. Oh I almost forgot, we just wanted to code right? So you need a code editor? Prices are from $50 to $500. Don’t we all love notepad?"

    @leftSide.addSubView paraTwo = new KDView
      tagName     : 'p'
      partial     : "We thought this was unfair as much as it was stupid. Unfair because, we ran an outsourcing company for years, and we saw that what you call 'affordable' here, is not affordable 'there'. What you call a 'cool gadget' here, is an unreachable dream to many over there. You know where. Stupid because <em>the current process of getting web apps to run is far behind what can be achieved with today's technology</em>."

  putBetterPlace:->
    @leftSide.addSubView header = new KDView
      tagName     : 'h3'
      partial     : 'Making The Web A Better Place'

    @leftSide.addSubView paraOne = new KDView
      tagName     : 'p'
      partial     : "So&hellip; if open source is about collaboration and giving developers equal chances, we thought, If we could first remove those stupid barriers, uploading, downloading, setting up servers; secondly and most importantly, we felt obliged to do something for those who can only spare a few bucks a month to send it to their families."

    @leftSide.addSubView paraTwo = new KDView
      tagName     : 'p'
      partial     : "I wanted to have a tool like this for myself too. And we decided to get this done."

    @leftSide.addSubView paraThree = new KDView
      tagName     : 'p'
      partial     : "And here we are today with Koding. We hope while you enjoy using the system, you will take a moment to think, the difference we all can make for those of us who do not have the resources to make their dreams come true."

  putFree:->
    @leftSide.addSubView header = new KDView
      tagName     : 'h3'
      partial     : 'Let&rsquo;s Be Free'

    @leftSide.addSubView paraOne = new KDView
      tagName     : 'p'
      partial     : "Koding was originally seeded and funded by us up until this summer, when we met some amazing people who shared our dream of a better world for developers."

    @leftSide.addSubView paraTwo = new KDView
      tagName     : 'p'
      partial     : "Our plan is this: our free accounts will always be free, and be enough for every developer to go out, develop and make money without worrying about how to get crack software or how to pay for legal software. Our free accounts are not designed to frustrate developers so that they end up paying or leaving; They are designed to make them happy and stay here as long as they want."

    @leftSide.addSubView paraThree = new KDView
      tagName     : 'p'
      partial     : "As we build in more features, we'll eventually have some premium features for companies to build teams and have their own Koding as well as the ability to purchase more resources. We will only require a paid-plan if you want to have a lot of storage and traffic, private domains etc. This is a project that will ask companies to pay fees per user and it will stay free for developers forever with the features that developers need to get their apps running."

    @leftSide.addSubView paraFour = new KDView
      tagName     : 'p'
      partial     : "Welcome to our community!"

    @leftSide.addSubView paraFive = new KDView
      tagName     : 'p'
      partial     : "<strong>Devrim Yasar</strong>Co-Founder and CEO"

    @leftSide.addSubView paraSix = new KDView
      tagName     : 'p'
      partial     : "-on behalf of the Koding team!"

  
  putLocation:->
    @leftSide.addSubView locationView = new KDView
      cssClass    : 'location'

    locationView.addSubView para = new KDView
      tagName     : 'p'
      cssClass    : 'loc-first'
      partial     : "<strong>We're located at SOMA district in San Francisco, California.</strong>"

    locationView.addSubView para = new KDView
      tagName     : 'p'
      partial     : "Koding, Inc<br />153 Townsend St, Suite 90xx<br />San Francisco, CA 94107"

    locationView.addSubView para = new KDView
      tagName     : 'p'
      
    # para.addSubView contact = new KDView
      # tagName     : 'a'
      # partial     : 'Contact Us'
      # click       :(event)-> noop

    para.addSubView map = new KDView
      tagName     : 'a'
      partial     : 'Google Map'
      attributes  :
        href        : 'http://g.co/maps/q5zn3'
        target      : '_blank'
        
    @leftSide.addSubView firstLine = new KDView
      cssClass    : 'first-line'
        
    @leftSide.addSubView secondLine = new KDView
      cssClass    : 'second-line'
  
    
  putTeam:->
    for teamMember in @theTeam
      {name, job, image} = teamMember
      @rightSide.addSubView member = new KDView
        cssClass    : 'teammember'
        partial     : """
          <img src="#{image}" />
          <p><strong>#{name}</strong>#{job}</p>
        """
        
    
  theTeam:
    [
      {
        name      : 'Aleksey Mykhailov' 
        job       : 'Sys Admin &amp; node.js Developer'
        image     : '../images/people/aleksey.jpg'
      },
      # {
      #   name      : 'Bob Budd' 
      #   job       : 'Senior Frontend Engineer'
      #   image     : '../images/people/bob.jpg'
      # },
      {
        name      : 'Chris Thorn (w/ Milo)' 
        job       : 'Director of Engineering'
        image     : '../images/people/chris.jpg'
      },
      {
        name      : 'Devrim Yasar' 
        job       : 'Co-Founder &amp; CEO'
        image     : '../images/people/devrim.jpg'
      },
      {
        name      : 'Ryan Goodman' 
        job       : 'Director of User Experience'
        image     : '../images/people/ryan.jpg'
      },
      # {
      #   name      : 'Saleem Abdul Hamid'
      #   job       : 'Senior node.js Engineer'
      #   image     : '../images/people/saleem.jpg'
      # },
      {
        name      : 'Sinan Yasar' 
        job       : 'Co-Founder &amp; Chief UI Engineer'
        image     : '../images/people/sinan.jpg'
      },
      {
        name      : 'Victor Bucataru' 
        job       : 'C++ Developer'
        image     : '../images/people/victor.jpg'
      },
    ]
    
