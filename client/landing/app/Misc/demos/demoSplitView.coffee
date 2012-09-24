page_demoSplitView = (parentView)->
  a = new KDView
    size :
      width     : "1200px"       # npx/n%
      height    : "1200px"       # npx/n%
  
  b = new KDView
    size :
      width     : "400px"       # npx/n%
      height    : "300px"       # npx/n%
  c = new KDView()
  d = new KDView()
  e = new KDView()
  f = new KDView()
  g = new KDView()
  h = new KDView()

  i = new KDView
    size :
      width     : "40px"       # npx/n%
      height    : "40px"       # npx/n%
    position :
      vertically    : "bottom"  # top/center/bottom
      horizontally  : "right"    # left/center/right
  j = new KDView
    size :
      width     : "40px"       # npx/n%
      height    : "40px"       # npx/n%
    position :
      vertically    : "top"  # top/center/bottom
      horizontally  : "left"    # left/center/right
  k = new KDView
    size :
      width     : "25%"       # npx/n%
      height    : "25%"       # npx/n%
    position :
      vertically    : "center"  # top/center/bottom
      horizontally  : "center"    # left/center/right

  topMiddleSplit = new SplitView
    type  : "horizontal"
    views : [a,b,c]
    sizes : ["33%","34%","33%"]

  bottomSplit = new SplitView
    type  : "vertical"
    views : [d,e,f]
    sizes : ["33%","34%","33%"]

  topSplit = new SplitView
    type  : "vertical"
    views : [g,topMiddleSplit,h]
    sizes : ["33%","34%","33%"]

  mainSplit = new SplitView
    type  : "horizontal"
    views : [topSplit,bottomSplit]


  parentView.addSubView mainSplit
  a.addSubView i
  a.addSubView j
  g.addSubView k

  a.setRandomBG()
  b.setRandomBG()
  c.setRandomBG()
  d.setRandomBG()
  e.setRandomBG()
  f.setRandomBG()
  g.setRandomBG()
  h.setRandomBG()
  i.setRandomBG()
  j.setRandomBG()
  k.setRandomBG()