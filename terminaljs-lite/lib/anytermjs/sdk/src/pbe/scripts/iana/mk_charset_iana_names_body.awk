BEGIN	{ print "const char * const charset_iana_names[] = {"; }
NF>0	{ printf("  \"%s\",\n",$1); }
END	{ print "  NULL";
          print "};"; }

