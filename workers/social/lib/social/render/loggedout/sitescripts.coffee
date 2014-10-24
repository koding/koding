TYPEKITIDS =
  hackathon : 'ndd8msy'
  landing   : 'rbd0tum'

module.exports = (campaign) ->

  scripts =
    """
    <script>
      (function(d) {
        var config = {
          kitId: '#{TYPEKITIDS[campaign]}',
          scriptTimeout: 3000
        },
        h=d.documentElement,t=setTimeout(function(){h.className=h.className.replace(/\bwf-loading\b/g,"")+" wf-inactive";},config.scriptTimeout),tk=d.createElement("script"),f=false,s=d.getElementsByTagName("script")[0],a;h.className+=" wf-loading";tk.src='//use.typekit.net/'+config.kitId+'.js';tk.async=true;tk.onload=tk.onreadystatechange=function(){a=this.readyState;if(f||a&&a!="complete"&&a!="loaded")return;f=true;clearTimeout(t);try{Typekit.load(config)}catch(e){}};s.parentNode.insertBefore(tk,s)
      })(document);
    </script>
    """

  switch campaign

    when 'hackathon' then scripts += require './scripts/hackathon'
    else scripts += ''


  return scripts


