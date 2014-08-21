#!/usr/bin/perl -w
print "Content-Type: text/html\n\n";
print <<HTML;
<!DOCTYPE html>
<html lang=\"en\">
<head>  <meta charset=\"utf-8\">
  <title>Hello World from Perl by Koding</title>
  <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
  <link rel=\"stylesheet\" href=\"//koding.com/hello/css/style.css\">
  <!--[if IE]>
          <script src=\"//html5shiv.googlecode.com/svn/trunk/html5.js\"></script>
  	<![endif]-->
  <link href='//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800' rel='stylesheet' type='text/css'>
</head>
<body class=\"perl\">
  <div id=\"container\">
    <div id=\"main\" role=\"main\"  class=\"hellobox\" >
<header><a href=\"http://koding.com\">Koding.com</a></header>
    <h1>Hello World!</h1>
    <h2>From Perl $^V</h2>
   </div>
<nav>
	<ul>
    <li><a href="index.html">HTML</a></li>
		<li><a href=\"php.php\">PHP</a></li>
		<li><a href=\"python.py\">Python</a></li>
		<li><a class=\"active\" href=\"perl.pl\">Perl</a></li>
		<li><a href=\"ruby.rb\">ruby</a></li>
	</ul>    
</nav>
<footer>
<h4>This is an example page running Perl on your Koding Server.</h4> <p>You can create your own simple Perl \"Hello World\" with this:</p>
<pre>#!/usr/bin/perl -w
print \"Content-type: text/html&#92;n&#92;n&#92;n\";
print \"Hello, world from perl!&#92;n\";</pre>
</footer>
</div> 
</body>
</html>
HTML
exit;
