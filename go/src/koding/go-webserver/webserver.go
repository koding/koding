package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"net/http"
	"time"
)

var (
	configProfile = flag.String("c", "", "Configuration profile from file")
)

func initialize() {
	flag.Parse()
	if *configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	conf := config.MustConfig(*configProfile)
	modelhelper.Initialize(conf.Mongo)
}

func main() {
	initialize()

	http.HandleFunc("/", HomeHandler)
	http.ListenAndServe(":6500", nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	cookie, err := r.Cookie("clientId")
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	session, err := modelhelper.GetSession(cookie.Value)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	username := session.Username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	machines, err := modelhelper.GetMachines(username)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	workspaces, err := modelhelper.GetWorkspaces(account.Id)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	index := buildIndex(account, machines, workspaces)

	fmt.Fprintf(w, index)
	fmt.Println(time.Since(start))
}

func buildIndex(account *models.Account, machines []*modelhelper.MachineContainer, workspaces []*models.Workspace) string {
	accountJson, _ := json.Marshal(account)
	machinesJson, _ := json.Marshal(machines)
	workspacesJson, _ := json.Marshal(workspaces)

	return fmt.Sprintf(` <!doctype html>
<html lang="en">
<head>
  <title>Koding | A New Way For Developers To Work</title>
  <meta charset="utf-8"/>
<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"/>
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black">
<meta name="apple-mobile-web-app-title" content="Koding" />
<meta name="viewport" content="user-scalable=no, width=device-width, initial-scale=1" />
<link rel="shortcut icon" href="/a/images/favicon.ico" />
<link rel="fluid-icon" href="/a/images/logos/fluid512.png" title="Koding" />
<link rel="stylesheet" href="/a/css/kd.css?44e06fcb" />
<link rel="stylesheet" href="/a/css/koding.css?44e06fcb" />
</head>
<body class='logged-in'>

  <!--[if IE]><script>(function(){window.location.href='/unsupported.html'})();</script><![endif]-->

  <script>var KD = {"config":{"kites":{"disableWebSocketByDefault":true,"stack":{"force":true,"newKites":true},"kontrol":{"username":"koding"},"os":{"version":">=0.4.0, <0.5.0"},"terminal":{"version":">=0.2.0, <0.3.0"},"klient":{"version":"0.0.1"},"kloud":{"version":"0.0.1"}},"algolia":{"appId":"DYVV81J2S1","apiKey":"303eb858050b1067bcd704d6cbfb977c","indexSuffix":".sandbox"},"logToExternal":false,"suppressLogs":false,"logToInternal":false,"authExchange":"auth","environment":"sandbox","version":"44e06fcb","resourceName":"koding-social-sandbox","userSitesDomain":"sandbox.koding.io","logResourceName":"koding-social-sandboxlog","socialApiUri":"/xhr","apiUri":"/","mainUri":"/","sourceMapsUri":"/sourcemaps","broker":{"uri":"/subscribe"},"appsUri":"/appsproxy","uploadsUri":"https://koding-uploads.s3.amazonaws.com","uploadsUriForGroup":"https://koding-groups.s3.amazonaws.com","fileFetchTimeout":15000,"userIdleMs":300000,"embedly":{"apiKey":"94991069fb354d4e8fdb825e52d4134a"},"github":{"clientId":"d3b586defd01c24bb294"},"newkontrol":{"url":"https://sandbox.koding.com/kontrol/kite"},"sessionCookie":{"maxAge":1209600000,"secure":false},"troubleshoot":{"idleTime":3600000,"externalUrl":"https://s3.amazonaws.com/koding-ping/healthcheck.json"},"recaptcha":"6LfZL_kSAAAAABDrxNU5ZAQk52jx-2sJENXRFkTO","stripe":{"token":"pk_test_S0cUtuX2QkSa5iq0yBrPNnJF"},"externalProfiles":{"google":{"nicename":"Google"},"linkedin":{"nicename":"LinkedIn"},"twitter":{"nicename":"Twitter"},"odesk":{"nicename":"oDesk","urlLocation":"info.profile_url"},"facebook":{"nicename":"Facebook","urlLocation":"link"},"github":{"nicename":"GitHub","urlLocation":"html_url"}},"entryPoint":{"slug":"koding","type":"group"},"roles":["member"],"permissions":[]}};</script>
  <script>KD.isLoggedInOnLoad=true;</script>
  <!-- SEGMENT.IO -->
<script type="text/javascript">
  window.analytics||(window.analytics=[]),window.analytics.methods=["identify","track","trackLink","trackForm","trackClick","trackSubmit","page","pageview","ab","alias","ready","group","on","once","off"],window.analytics.factory=function(t){return function(){var a=Array.prototype.slice.call(arguments);return a.unshift(t),window.analytics.push(a),window.analytics}};for(var i=0;window.analytics.methods.length>i;i++){var method=window.analytics.methods[i];window.analytics[method]=window.analytics.factory(method)}window.analytics.load=function(t){var a=document.createElement("script");a.type="text/javascript",a.async=!0,a.src=("https:"===document.location.protocol?"https://":"http://")+"d2dq2ahtl5zl1z.cloudfront.net/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(a,n)},window.analytics.SNIPPET_VERSION="2.0.8",
  window.analytics.load("4c570qjqo0");
  window.analytics.page();
</script>

<script>KD.config.usePremiumBroker=false</script>
<script>KD.userAccount=%s</script>
<script>KD.userMachines=%s</script>
<script>KD.userWorkspaces=%s</script>
<script>KD.currentGroup={"bongo_":{"constructorName":"JGroup","instanceId":"3550680c3c1cd86c7894cf4c3c04d606"},"data":{"slug":"koding","_id":"5196fcb2bc9bdb0000000027","body":"Say goodbye to your localhost","title":"Koding","privacy":"private","visibility":"visible","socialApiChannelId":"5921864421902123009","parent":[],"customize":{"background":{"customType":"defaultImage","customValue":"1"}},"counts":{"members":80},"migration":"completed","stackTemplates":["53925a609b76835748c0c4fd"],"socialApiAnnouncementChannelId":"5921866536103968771"},"title":"Koding","body":"Say goodbye to your localhost","socialApiChannelId":"5921864421902123009","socialApiAnnouncementChannelId":"5921866536103968771","slug":"koding","privacy":"private","visibility":"visible","counts":{"members":80},"customize":{"background":{"customType":"defaultImage","customValue":"1"}},"stackTemplates":["53925a609b76835748c0c4fd"],"_id":"5196fcb2bc9bdb0000000027"}</script>
<script src='/a/js/kd.libs.js?44e06fcb'></script>
<script src='/a/js/kd.js?44e06fcb'></script>
<script src='/a/js/koding.js?44e06fcb'></script>
<script>
  KD.utils.defer(function () {
    KD.currentGroup = KD.remote.revive(KD.currentGroup);
    KD.userAccount = KD.remote.revive(KD.userAccount);
  });
</script>

<!-- Google Analytics -->
<script>
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

ga('create', 'UA-6520910-8', 'auto');

// we hook onto KD router 'RouteInfoHandled' to send page views instead,
// see analytic.coffee
//ga('send', 'pageview');

</script>
<!-- End Google Analytics -->

</body>
</html>
`, accountJson, machinesJson, workspacesJson)
}
