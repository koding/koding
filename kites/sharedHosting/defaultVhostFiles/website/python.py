#!/usr/bin/python
import os
import platform
print "Content-Type: text/html"
print
print """\
<!DOCTYPE html>
<html lang="en">
<head>  <meta charset="utf-8">
  <title>Hello World from Python by Koding</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <link rel="stylesheet" href="//koding.com/hello/css/style.css">
  <!--[if IE]>
      	<script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
  <link href='//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800' rel='stylesheet' type='text/css'>
</head>
<body class="python">
  <div id="container">
    <div id="main" role="main"  class="hellobox" >
<header><a href="http://koding.com">Koding.com</a></header>
    <h1>Hello World!</h1>
    <h2>From Python 
    """
print platform.python_version()
print """\
  </h2> </div>
<nav>
	<ul>
    <li><a href="index.html">HTML</a></li>
		<li><a href="php.php">PHP</a></li>
		<li><a class="active" href="python.py">Python</a></li>
		<li><a href="perl.pl">Perl</a></li>
		<li><a href="ruby.rb">ruby</a></li>
	</ul>    
</nav>
<footer>
<h4>This is an example page running Python on your Koding Server.</h4> <p>You can create your own simple Python "Hello World" with this:</p>
<pre>#!/usr/bin/python
import os
print "Content-type: text/html"
print
print "Hello, world from python!"</pre>
</footer>
</div> 
</body>
</html>
"""
