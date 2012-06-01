BEGIN	{ print "const char * const charset_mime_names[] = {"; }
NF>0	{ N=$1;
	  for (i=2; i<=NF; i++) {
	    if ($i=="*") {
	      i++;
	      N=$i;
	      break;
	    }
	  }
	  printf("  \"%s\",\n",N);
	}
END	{ print "  NULL";
	  print "};"; }

