class Metadata.Vote
  
  Metadata.defineFlags @,
    new Flag options: [
      t 'Vote up'
      t 'Vote down'
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
    
        upVotes   = flag.results[  'Vote up'] or []
        downVotes = flag.results['Vote down'] or []

        upVoteCount   = upVotes.length
        downVoteCount = downVotes.length

        myId = account.getId()
        
        try
          isMyVote = myId.equals.bind(myId)
          myUpVote =   _(  upVotes).detect isMyVote
          myDownVote = _(downVotes).detect isMyVote
        catch e
        
        myVote = if myUpVote then 'Vote up' else if myDownVote then 'Vote down'
      
        results = {
          upVoteCount
          downVoteCount
          myVote
        }
  
      {
        type
        replyId
        results
      }