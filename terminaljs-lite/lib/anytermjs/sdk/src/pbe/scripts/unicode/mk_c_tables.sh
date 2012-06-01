#!/bin/sh

echo "iso8859_table_t iso8859_tables[] = {"

for n in 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
do
  if [ $n == 12 ]
  then
    echo "  // ISO-8859-12 does not exist"
    echo "  {},"
  else
    echo "  // ISO-8859-${n}"
    echo -n "  {"
    awk 'BEGIN { L = -1; }
         !/^#/ && !/^ *$/ {
                 N = strtonum($1); U = $2;
                 if (N < L) { print "Table is out of order"; exit(1); }
                 while (L<N-1) { printf(" -1,"); L++; }
                 if (N<=160) {
                   if (strtonum(U) != N) {
                     print "expected 1-1 mapping does not hold"; exit(1);
                   }
                 } else {
                   printf(" %s,",U);
                 }
                 L = N;
               }' < "tables/ISO8859/8859-${n}.TXT"
    echo "},"
  fi
done

echo "};"

