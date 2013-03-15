class bController extends KDViewController
  constructor:()->
    super()
    #@listenTo tank,["mousedown"],@my
    @listenTo tank,["keydown"],@move
    #@listenTo otherTanks,["somethingHappened"],@otherTanks
  
  my:(p,e)->
  
  move:(p,e)->
    switch e.which
      when 38 then @goUp()
      when 40 then @goDown()
      when 37 then @goLeft()
      when 39 then @goRight()
      when 32 then @fire p
  
  fire:(tank)->
    f = new mermi 
      parent:"body"
    #@getDomElement().addSubView f
    b = @getDomElement().getBounds()
    f.getDomElement().css
      top: b.y
      left: b.x+b.w/2
      
    f.getDomElement().animate
      top: -10
    ,5000
    
  goUp:->
    @getDomElement().getDomElement().animate 
      top:"-=10px"
    ,50
  
  goDown:->
    @getDomElement().getDomElement().animate 
      top:"+=10px"
    ,50    
  goLeft:->
    @getDomElement().getDomElement().animate 
      left:"-=10px"
    ,50
  goRight:->    
    @getDomElement().getDomElement().animate 
      left:"+=10px"
    ,50

class mermiController extends KDViewController
  constructor:()->
    super()
    
  

class mermi extends KDView
  constructor:(options)->
    super options
    @setWidth 5
    @setHeight 5
    @getDomElement().css
      position:"absolute"
      backgroundColor:__utils.getRandomRGB()    

class tank extends KDView
  constructor:()->
    super()
    @setWidth 20
    @setHeight 20
    @getDomElement().css
      position:"absolute"
      top:"400px"
      left:"400px"
      backgroundColor:__utils.getRandomRGB()


    

class splitter extends SplitView

class tankShooterGame extends KDViewController
  constructor:()->
    super()


  init:()->
        
    bcont = new bController()
    ccont = new bController()
    a = new KDView("main")
    tank1 = new tank()
    tank2 = new tank()

    #a.addSubView b 
    
    left = new KDView()
    right= new KDView()
    
    left.addSubView tank1
    right.addSubView tank2
    
    split = new splitter
      views: [left,right]
    #split.setDelegate @
    a.addSubView split
  
  viewAppended:()->
    log "iikiolo"

#@getSingleton('mainController') = new tankShooterGame()
