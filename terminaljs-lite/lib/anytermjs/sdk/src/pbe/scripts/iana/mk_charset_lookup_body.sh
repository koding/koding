#!/bin/sh

awk '
function to_ident(n) {
  n = tolower(n);
  gsub("[-:.()+_]","_",n);
  return n;
}
function to_key(n) {
  n = tolower(n);
  n = gensub("([[:digit:]])[-:.()+_]+([[:digit:]])","\\1@\\2","g",n);
  n = gensub("([[:digit:]])[-:.()+_]+([[:digit:]])","\\1@\\2","g",n);
  gsub("[-:.()+_]","",n);
  gsub("@","_",n);
  return n;
}
NF>0	{ ident = to_ident($1);
          for (i=1; i<=NF; i++) {
            if ($i != "*") {
              aliases[to_key($i)] = 1;
            }
          }
          for (A in aliases) {
            printf("  {\"%s\", cs::%s},\n", A, ident);
          }
          delete aliases;
        }
' |
LC_ALL=C sort -t '"'


