<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Hello World From php by Koding</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<link rel="stylesheet" href="//koding.com/hello/css/style.css">
<!--[if IE]>
      	<script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
  	<![endif]-->
<link href='//fonts.googleapis.com/css?family=Source+Sans+Pro:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800' rel='stylesheet' type='text/css'>
</head>
<body class="php">
<div id="container">
	<div id="main" role="main" class="hellobox">
		<header><a href="http://koding.com">Koding.com</a></header>
		<h1><?php echo 'Hello World!'; ?>
		</h1>
		<h2>From PHP <?php echo PHP_VERSION; ?>
		</h2>
	</div>
	<nav>
	<ul>
		<li><a href="index.html">HTML</a></li>
		<li class="active"><a href="php.php">PHP</a></li>
		<li><a href="python.py">Python</a></li>
		<li><a href="perl.pl">Perl</a></li>
		<li><a href="ruby.rb">ruby</a></li>
	</ul>
	</nav>
	<footer>
	<h4>This is an example page running PHP on your Koding Virtual Machine (VM).</h4>
	<p>
		You can create your own PHP based "Hello World" program by following this <a href="https://koding.com/docs/hello-world/php" target=_blank>simple guide</a> over at Koding University.
	</p>
	<p id="social"><a id="twitter" href="https://twitter.com/koding" target=_blank>Twitter</a><a id="facebook" href="https://facebook.com/koding" target=_blank>Facebook</a></p>
	<!-- pre>&lt;?php echo 'Hello World from PHP'; ?&gt;</pre -->
	</footer>
</div>
</body>
</html>
