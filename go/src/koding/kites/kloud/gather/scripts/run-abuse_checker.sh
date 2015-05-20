#!/usr/bin/env bash
MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh

function found() {
  COUNT=`grep $1 -r /home/ 2> /dev/null | wc -l`

  if [ $COUNT -gt 0 ]
  then
    output "$2" $BOOLEAN true
    exit
  fi
}

found 'send(crazy, 0, $size, sockaddr_in($port, $iaddr));' 'abuse: ddos'
found 'DDoSing the IP' 'abuse: ddos'
found 'TOOL DDOS DIE' 'abuse: ddos'
found 'Deskdubstep' 'abuse: ddos'
found 'Written by Sotd' 'abuse: possible ddos (Sotd)'

found 'Python Vulnerability Scanner' 'abuse: python vulnerability scanner'
found 'Scans for FTP servers' 'abuse: ftp scan'

found 'HULK DG Tan cong' 'abuse: suspicious script'
found 'PT47 Attack Started' 'abuse: suspicious script'

found 'Facebook Cracker Version' 'abuse: facebook abuse'
found 'facebook bruteforcer' 'abuse: facebook abuse'
found 'yudha.gunslinger@gmail.com' 'abuse: possible facebook abuse (yudha)'
found 'http://autolikefb.org/f5.html' 'abuse: facebook autolike'
found 'author: KIT HERO' 'abuse: possible ddos (KIT HERO)'
found 'Slowloris' 'abuse: slowloris ddos'
