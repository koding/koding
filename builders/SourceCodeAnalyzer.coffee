class SourceCodeAnalyzer
  tree = 
    Client : [["name","parent","tooltip"]]
    Server : [["name","parent","tooltip"]]
  constructor:->
    @tree = tree
  checkClass = (txt)->
    re1 = "(class)" # Word 1
    re2 = "(\\s+)" # White Space 1
    re3 = "((?:[a-z][a-z0-9_]*))" # Variable Name 1
    p = new RegExp(re1 + re2 + re3, ["i"])
    m = p.exec(txt)
    if m?
      word1 = m[1]
      ws1 = m[2]
      var1 = m[3]
      return var1
    else
      return false

  checkClassExtends = (txt)->
    re1 = "(class)" # Word 1
    re2 = "(\\s+)" # White Space 1
    re3 = "((?:[a-z][a-z0-9_]*))" # Variable Name 1
    re4 = "(\\s+)" # White Space 2
    re5 = "(extends)" # Word 2
    re6 = "(\\s+)" # White Space 3
    re7 = "((?:[a-z][a-z0-9_]*))" # Variable Name 2
    p   = new RegExp(re1 + re2 + re3 + re4 + re5 + re6 + re7, ["i"])
    m   = p.exec(txt)
    if m?
      word1 = m[1]
      ws1   = m[2]
      var1  = m[3]
      ws2   = m[4]
      word2 = m[5]
      ws3   = m[6]
      var2  = m[7]
      return [var1,var2]
    else
      return false

  check=(line)->

    if line.substr(0,6) is "class "

      if line.indexOf(" extends ") > 0
        lineArr = line.split ' '
        return [lineArr[1],lineArr[3]]
      else        
        return [line.substr(6)]
    else
      return false


  add: (file)->
    csFileContents = file.contentsCs

    # unless csFileContents
    #   delete file.contents
    #   console.log file
    #   process.exit

    csArr = csFileContents.split "\n"
    # txt = csFileContents
    notAllowed = [
      'or','in','null','name','becomes','of','for','is','delegate',
      'to','options','api','style','newStyle','iconClass','else',
      'viewOptions','LEVEL','CONTEXT'
    ]

    for cl in csArr
      # a = checkClass cl
      # b = checkClassExtends cl
      a = check cl
      if a and a.length is 1
        tree[file.section].push [a[0],file.section,null]
      else if a
        tree[file.section].push [a[0],a[1],null]
      else
        # nothing to do.



 module.exports = SourceCodeAnalyzer