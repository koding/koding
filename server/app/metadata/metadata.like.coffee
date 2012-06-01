class Metadata.Like
  
  Metadata.defineFlags @,
    new Flag options: [
      t 'Like'
    ]
  
  @outputFilters =
    
    groupFilter: (elements)->
      out = {}
      for element in elements
        out[element.replyId or 'root'] = element
      out
    
    elementFilter: (rawMetadata, account)->
      {type, replyId} = rawMetadata
  
      if flag = rawMetadata.get 'flags.0'
        
        likes = flag.results['Like'] or []
        likeCount = likes.length

        myId = account.getId()
        
        try
          isMyLike = myId.equals.bind(myId)
          myLike =   _(  likes).detect isMyLike
        catch e
        
        myLike = if myLike then 'Like'
      
        results = {
          likeCount
          myLike
        }
  
      {
        type
        replyId
        results
      }