###
  todo
    - dynamic table of contents (with real data)
    - page switching ui
    - activity
    - develop fake button items and styling
    - flip pages by clicking left or right half of the pages
###

class BookView extends JView

  @lastIndex = 0

  constructor: (options = {},data) ->

    options.domId    = "instruction-book"
    options.cssClass = "book"

    super options, data

    @currentIndex = 0

    @right = new KDView
      cssClass : "right-page right-overflow"
      click    : -> @setClass "flipped"

    @left = new KDView
      cssClass : "left-page fl"

    @putOverlay cssClass : "", isRemovable : yes, animated : yes
    @once "OverlayAdded", =>
      @$overlay.css zIndex : 999

    @once "OverlayWillBeRemoved", =>
      @unsetClass "in"

    @once "OverlayRemoved", =>
      @destroy()

    @setKeyView()
    @registerSingleton "InstructionsBook", @

  pistachio:->

    """
    {{> @left}}
    {{> @right}}
    """

  click:-> @setKeyView()

  keyDown:(event)->

    switch event.which
      when 37 then do @fillPrevPage
      when 39 then do @fillNextPage

  getPage:(index = 0)->

    @currentIndex = index
    
    page = new BookPage 
      delegate : @
    , __bookPages[index]

    return page

  fillPrevPage:->

    return if @currentIndex - 1 < 0
    BookView.lastIndex = @currentIndex - 1
    @fillPage @currentIndex - 1

  fillNextPage:->

    return if __bookPages.length is @currentIndex + 1
    BookView.lastIndex = @currentIndex + 1
    @fillPage @currentIndex + 1

  fillPage:(index)->

    index or= BookView.lastIndex
    page = @getPage index
    @right.setClass "out"
    @utils.wait 300, =>
      @setClass "in"
      @right.destroySubViews()
      @right.addSubView page
      @right.unsetClass "out"





class BookPage extends JView

  constructor: (options = {},data) ->

    data.cssClass  or= ""
    data.content   or= ""
    data.profile     = KD.whoami().profile
    options.cssClass = "page #{@utils.slugify data.title} #{data.cssClass} #{unless data.title then "no-header"}"
    options.tagName  = "section"

    super options, data

    @header = new KDView
      tagName   : "header"
      partial   : "#{data.title}"
      cssClass  : "hidden" unless data.title

    @content = new KDView
      tagName   : "article"
      cssClass  : "content-wrapper"
      pistachio : data.content
    , data

    konstructor = if data.embed then data.embed else KDCustomHTMLView

    @embedded = new konstructor
      delegate : @getDelegate()

  pistachio:->

    """
    {{> @header}}
    {{> @content}}
    <div class='embedded'>
      {{> @embedded}}
    </div>
    """


class BookTableOfContents extends JView

  pistachio:->

    tmpl = ""
    for page, nr in __bookPages
      if page.title and page.anchor isnt no
        tmpl += "<a href='#'>#{page.title}</a><span>#{nr+1}</span><br>"

    return tmpl

  click:(event)->
    if $(event.target).is("a")
      nr = parseInt($(event.target).next().text(), 10)-1
      @getDelegate().fillPage nr


class BookUpdateWidget extends KDView

  viewAppended:->

    @setPartial "<span class='button'></span>"
    @addSubView @statusField = new KDHitEnterInputView
      type          : "text"
      defaultValue  : "Hello World!"
      focus         : => @statusField.setKeyView()
      click         : (pubInst, event)=> 
        event.stopPropagation()
        no
      validate      :
        rules       :
          required  : yes
      callback      : (status)=> @updateStatus status

    @statusField.$().trigger "focus"


  updateStatus:(status)->

    @getDelegate().$().css left : -1349

    bongo.api.JStatusUpdate.create body : status, (err,reply)=>
      @utils.wait 2000, =>
        @getDelegate().$().css left : -700
      unless err
        appManager.tell 'Activity', 'ownActivityArrived', reply
        new KDNotificationView
          type     : 'growl'
          cssClass : 'mini'
          title    : 'Message posted!'
          duration : 2000
        @statusField.setValue ""
        @statusField.setPlaceHolder reply.body
      else
        new KDNotificationView type : "mini", title : "There was an error, try again later!"

class BookTopics extends KDView

  viewAppended:->
    
    @addSubView loader = new KDLoaderView
      size          : 
        width       : 60
      loaderOptions :
        color       : "#666666"
        shape       : "spiral"
        diameter    : 60
        density     : 60
        range       : 0.6
        speed       : 2
        FPS         : 25

    @utils.wait -> loader.show()
    
    appManager.tell "Topics", "fetchCustomTopics",
      limit : 20
    , (err, topics)=>
      loader.hide()
      unless err
        for topic in topics
          @addSubView topicLink = new TagLinkView null, topic
          topicLink.registerListener
            KDEventTypes : "click"
            listener     : @
            callback     : =>
              @getDelegate().$().css left : -1349
              @utils.wait 4000, =>
                @getDelegate().$().css left : -700


class BookDevelopButton extends KDButtonViewWithMenu


__bookPages = [

    title     : "Table of Contents"
    anchor    : no
    embed     : BookTableOfContents
  ,
    title     : "A Story"
    content   : "Once upon a time, there were developers just like you<br/>Despite the sea between them, development had ensued"
  ,
    cssClass  : "a-story more-1"
    content   : "Over time they noticed, that ‘how it’s done’ was slow<br/>“With 1,000 miles between us, problems start to show!”"
  ,
    cssClass  : "a-story more-2"
    content   : "“Several different services for just a hello world?<br/>And each a different cost!” Their heads began to swirl."
  ,
    cssClass  : "a-story more-3"
    content   : "They made up their minds, “It’s time to leave the crowd</br>all of these environments should reside in the cloud!”"
  ,
    cssClass  : "a-story more-4"
    content   : "“Then simplify the process, from several steps to one<br/>A terminal in a browser? That would help a ton!”"
  ,
    cssClass  : "a-story more-5"
    content   : "Build it on a community, we'll teach and learn together<br/>Of course we'll charge nothing for it."
  ,
    cssClass  : "a-story more-6"
    content   : "“This sounds amazing!” They each began to sing,<br/>“Let’s package it together and call it Koding!”"
  ,
    title     : "Foreword"
    content   : """<p>Koding is a developer community and cloud development environment that gives you a full stack of collaboration & development tools in your browser.</p>
                   <p>New to Koding? This tutorial will have you developing, publishing and sharing in no time.</p>
                   <p>So sit back, relax, and enjoy this “How To”. Oh, and welcome home.</p>"""
  ,
    title     : "Activity"
    content   : "<p>Think of this as the town center of Koding. Ask questions, get answers, start a discussion...be social! Community can be a great tool for development, and here’s the place to get started. In fact, let’s start with your first status update!</p>"
    embed     : BookUpdateWidget
  ,
    title     : "Topics"
    embed     : BookTopics
    content   : """<p>Wouldn’t it be great if you could listen to only what you cared about? Well, you can! Topics let you filter content to your preferences. In addition to public tags, there are also private tags for within groups.</p>
                   <p>Select from a few of our most popular topics to the right. At anytime, you can return to the Topics board to Follow more, or stop following those you’ve selected.</p>
                   <p>Can’t find what you’re looking for? Start a new topic!</p>"""
  ,
    title     : "Members"
    content   : """<p>Welcome to the club!</p>
                   <p>Here you’ll find all of Koding’s members. Follow people you’re working with, you’re learning from, or maybe some that you just find interesting...</p>
                   <p>here’s your chance to connect and collaborate! Feel free to follow the whole Koding Team!</p>"""
  ,
    title     : "Develop"
    content   : """<p>This is what Koding is all about. Here, you can view, edit, and preview files. Here’s a quck tour of the tool.</p>
                   <p>Jump to Getting Started to find out how to start developing!</p>"""
  ,
    cssClass  : "develop more-1"
    content   : """<p>Looking for a somewhere to start? We’ve provided some example pages inside your “website” folder. Just navigate your file tree to:</p>
                   <strong>{{#(profile.nickname)}}/Sites/{{#(profile.nickname)}}.koding.com/website/</strong>
                   <p>This is where all of your public files are located. Here is also where you’ll want to build your webpage.</p>
                   <p>Brand new to web development? Read Building a Website to get started with the basics.</p>"""
  ,
    cssClass  : "develop more-2"
    content   : """<p>When you open a new file from the file tree, a new tab is created. Use tabs to manage working on multiple files at the same time.</p>
                   <p>You can also create a new file using either the “+” button on Tabs, or by right-clicking the file tree.</p>
                   <p>Save the new file to your file tree by clicking the save button to the right of your tabs. When you’re editing a file from your websites folder, you can preview that file in a new tab by clicking the “Eye” icon that appears next to the save button.</p>"""
  ,
    cssClass  : "develop more-3"
    content   : "Dont’ forget about your settings in the bottom corner. Here you can change the syntax, font, margins, and a whole lot of other features. Go ahead and check it out!"
    embed     : BookDevelopButton
  ,
    title     : "Apps"
    content   : """<p>What makes Koding so useful are the apps provided by its users. Here you can perform one click installs of incredibly useful applications provided by users and major web development tools.</p>
                   <p>In addition to applications for the database, there are add-ons, and extensions to get your projects personalized, polished, and published faster.</p>"""
  ,
    title     : "Etiquette"
    content   : """<p>Seems like a fancy word, huh? Don’t worry, we’re not going to preach. This is more of a Koding Mission Statement. Sure, Koding is built around cloud development, but it’s second pillar is community.</p>
                   <p>So what does that mean? That means that developers of all skill levels are going to grace your activity feed. Some need help, some will help others, some will guide the entire group, whatever your role is it’s important to remember one important word: help.</p>
                   <p>Help by providing insight and not insult to people asking basic questions. Help by researching your question to see if it has had already been given an answer. And lastly, help us make this service the best it can be!</p>"""
]
