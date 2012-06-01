function to_ident(n) {
  n = tolower(n);
  gsub("[-:.()+]","_",n);
  return n;
}
function add_aliases_rec(pref,suff,    pos,chunk,newsuff) {
  pos = index(suff,"_");
  if (pos>0) {
    chunk = substr(suff,0,pos-1);
    newsuff = substr(suff,pos+1);
    if (pref !~ "[[:digit:]]$" || suff !~ "^[[:digit:]]") {
      add_aliases_rec(pref chunk, newsuff);
    }
    if (pref!="") {
      add_aliases_rec(pref "_" chunk, newsuff);
    }
  } else if (pref=="") {
    aliases[suff]=1;
  } else {
    aliases[pref "_" suff]=1;
    if (pref !~ "[[:digit:]]$" || suff !~ "^[[:digit:]]") {
      aliases[pref suff]=1;
    }
  }
}
function add_aliases(A) {
  add_aliases_rec("",A);
}
BEGIN	{ print "enum charset_t {"; }
NF>0	{ CS=to_ident($1);
          printf("  %s,\n",CS);
          add_aliases(CS);
          for (i=2; i<=NF; i++) {
             if ($i != "*") {
               A=to_ident($i);
               add_aliases(A);
             }
          }
          for (A in aliases) {
             if (A!=CS && A !~ /^[[:digit:]]/) {
               printf("    %-26s= %s,\n",A,CS);
             }
          }
          delete aliases;
        }
END	{ print "  max_charset"; print "};"; }
