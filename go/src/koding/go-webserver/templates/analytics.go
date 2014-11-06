package templates

var Analytics = `
    <!-- SEGMENT.IO -->
    <script type="text/javascript">
      window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
      window.analytics.load("4c570qjqo0");
      window.analytics.page();
    </script>

    <!-- Google Analytics -->
    <script>
      (function(k,o,d,i,n,g){k['GoogleAnalyticsObject']=i;k[i]=k[i]||function(){
    (k[i].q=k[i].q||[]).push(arguments)},k[i].l=1*new Date();g=o.createElement(d),
      n=o.getElementsByTagName(d)[0];g.async=1;g.src='//www.google-analytics.com/analytics.js';
      n.parentNode.insertBefore(g,n)})(window,document,'script','ga');
      ga('create', 'UA-6520910-8', 'koding.com');ga('send', 'pageview');
    </script>
`
