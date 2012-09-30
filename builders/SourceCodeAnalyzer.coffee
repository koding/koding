{EventEmitter} = require 'events'

class SourceCodeAnalyzer
  fs = require 'fs'
  tree = []

  constructor:->
    @tree = tree

  attachListeners : (builder) ->
    builder.watcher.on "coffeeFileContents",@add

    builder.watcher.on "initDidComplete",=>
      @treeIsDrawn()

  treeIsDrawn:->
    fs.writeFileSync "./website/dev/sourceData.json",JSON.stringify tree,null,2
    b = findChildren "-Client"
    fs.writeFileSync "/Users/d/Projects/d3/examples/data/kdflare.json",JSON.stringify b,null,2

  findChildren = (rootNode) ->
    return ({name : item[0], children  : findChildren(item[0])} for item in tree when item[1] is rootNode)
  

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


    csArr = csFileContents.split "\n"

    for cl in csArr
      a = check cl
      if a and a.length is 1
        tree.push [a[0],"-"+file.section]
      else if a
        tree.push [a[0],a[1]]
      else
        # nothing to do.



 module.exports = SourceCodeAnalyzer