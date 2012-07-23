class DiffScript

  constructor:()->
    @source = ""

  dispatch: (scr)->
    if scr.charAt(0) is "n" 
      return @source
      
    if scr.charAt(0) is "R"
      @source = scr.substr 1
      return @source

    i=0
    cursor=0
    result=""
    while i<scr.length
      cmd=scr.charAt i
      i++
      m=scr.indexOf ":",i
      num=Number scr.substr i,m-i
      i=m+1
      switch cmd
        when "d"
          ###
            just forward the source cursor
          ###
          cursor+=num
        when "i"
          result+=scr.substr i,num
          i+=num
        when "k"
          result+=@source.substr cursor,num
          cursor+=num
    @source = result 
    return result

if not window?
  module.exports = DiffScript
