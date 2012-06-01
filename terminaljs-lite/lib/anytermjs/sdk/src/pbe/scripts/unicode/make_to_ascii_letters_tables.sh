# scripts/unicode/make_to_ascii_letters_tables.sh
# This file is part of libpbe; see http://svn.chezphil.org/libpbe/
# (C) 2008 Philip Endecott

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# Download the Unicode character database:
# wget http://www.unicode.org/Public/5.1.0/ucd/UnicodeData.txt

# Extract the decompositions:
cat UnicodeData.txt |
awk -F ';' '$6!="" {print $1,$6}' |
awk '/</ {printf("%s ",$1); for(i=3;i<=NF;i++) printf("%s ",$i); printf("\n");}
     !/</ {print}' > decompositions

# Each line in decompositions starts with the source character and is followed by the
# sequence of characters that it may be replaced by.  This replacement needs to be
# applied recursively:
while true
do

awk '{if (ARGIND==1) {d=""; for(i=2;i<=NF;i++) {d = d $i " "}; dec[$1]=d;}
                else {printf("%s ",$1);
                      for(i=2;i<=NF;i++) {
                        if ($i in dec) {printf("%s",dec[$i]);} else {printf("%s ",$i);}
                      } 
                      printf("\n");}
     }' decompositions decompositions > new_decompositions

if cmp decompositions new_decompositions
then
  break
fi

mv new_decompositions decompositions

done

mv new_decompositions full_decompositions


# For the puposes of converting strings to text searchable ASCII equivalents, we're only
# interested in determining the ASCII letter base characters.  Strip all the other characters
# in the expansion, and if none are left remove the line.

awk '{printf("%s ",$1);
      for(i=2;i<=NF;i++) {
        n=strtonum("0x" $i);
        if (n>=65 && n<=90 || n>=97 && n<=122)
          printf("%s ",$i)
        }
        printf("\n");
     }' full_decompositions |
awk '{if (NF>1) print}' |


# Now convert the letter codes to actual letters, and convert to lower case.

awk '{printf("%s \"",$1);
      for(i=2;i<=NF;i++) {
        v=strtonum("0x" $i);
        c=sprintf("%c",v);
        printf("%c",tolower(c));
      } 
      printf("\"\n");
     }' |

# Add 'identity' conversions for a-z and 'tolower' conversions for A-Z.

awk 'BEGIN {for(i=65;i<=90;i++) printf("%04X \"%c\"\n",i,i+32);
            for(i=97;i<=122;i++) printf("%04X \"%c\"\n",i,i);}
     {print}' > all_decompositions


# Add some more local decompositions.

cat >>all_decompositions <<EOF
00C6 "ae"
00D0 "d"
00D8 "o"
00DE "th"
00DF "ss"
00E6 "ae"
00F0 "d"
00F8 "o"
00FE "th"
0110 "d"
0111 "d"
0126 "h"
0127 "h"
0131 "i"
0141 "l"
0142 "l"
0152 "oe"
0153 "oe"
0166 "t"
0167 "t"
0180 "b"
0181 "b"
0182 "b"
0183 "b"
0186 "o"
0187 "c"
0188 "c"
0189 "d"
018A "d"
018B "d"
018C "d"
018E "e"
0190 "e"
0191 "f"
0192 "f"
0193 "g"
0195 "hv"
0197 "i"
0198 "k"
0199 "k"
019A "l"
019C "m"
019D "n"
019E "n"
019F "o"
01A0 "o"
01A1 "o"
01A2 "oi"
01A3 "oi"
01A4 "p"
01A5 "p"
01A6 "yr"
01AB "t"
01AC "t"
01AD "t"
01AE "t"
01AF "u"
01B0 "u"
01B2 "v"
01B3 "y"
01B4 "y"
01B5 "z"
01B6 "z"
01DD "e"
01E4 "g"
01E5 "g"
0220 "n"
0221 "d"
0223 "ou"
0224 "z"
0225 "z"
0234 "l"
0235 "n"
0236 "t"
0237 "j"
0238 "db"
0239 "qp"
023A "a"
023C "c"
023D "l"
023E "t"
023F "s"
0240 "z"
0243 "b"
0244 "u"
0245 "v"
0246 "e"
0247 "e"
0248 "j"
0249 "j"
024A "q"
024B "q"
024C "r"
024D "r"
024E "y"
024F "y"
0250 "a"
0253 "b"
0254 "o"
0255 "c"
0256 "d"
0257 "d"
0258 "e"
025B "e"
025C "e"
025D "e"
025E "e"
025F "j"
0260 "g"
0261 "g"
0262 "g"
0265 "h"
0266 "h"
0268 "i"
026A "i"
026B "l"
026C "l"
026D "l"
026F "m"
0270 "m"
0271 "m"
0272 "m"
0273 "n"
0274 "n"
0275 "o"
0276 "oe"
0279 "r"
027A "r"
027B "r"
027C "r"
027D "r"
027E "r"
027F "r"
0280 "r"
0281 "r"
0282 "s"
0284 "j"
0287 "t"
0288 "t"
0289 "u"
028B "v"
028C "v"
028D "w"
028E "y"
028F "y"
0290 "z"
0291 "z"
0297 "c"
0299 "b"
029A "e"
029B "g"
029C "h"
029D "j"
029E "k"
029F "l"
02A0 "q"
02A3 "dz"
02A5 "dz"
02A6 "ts"
02A8 "tc"
02AA "ls"
02AB "lz"
02AE "h"
02AF "h"
EOF


# Split it up into one file per unicode page

awk '{page=substr($1,1,length($1)-2); print>(page ".d0")}' all_decompositions


# Reformat them as struct initialisers:

for i in *.d0
do

n=`basename $i .d0`

echo -n "char_expansion_page_${n}_t to_ascii_letters_page_${n} [] = {";

awk '{n=strtonum("0x" $1); a[n%256]=$2;}
 END {for(i=0;i<256;i++) {
        if (i in a) printf("%s, ",a[i]); else printf("\"\", ");
      }
      printf("};\n")
     }' $i

done > to_ascii_letters_tables.cc


