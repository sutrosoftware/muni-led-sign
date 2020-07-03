#!/usr/bin/perl -w
# This script simply udpates the sign with more data.  If you need to write a
# more sophisticated client, just call this file from somewhere else.
# 
# Usage:
# ./lowlevel.pl --type=text
# Then, supply messages as stdin, in form of pictures comprized out of 0s and 1s
# for --type=pic, or as text for --type=text.  Separate messaages by double
# lines.

use strict qw(subs vars);
use warnings;
use Device::MiniLED;
my $sign=Device::MiniLED->new(devicetype => "sign");
$sign->addMsg(
   data => '',
   slot => 1
);
$sign->addMsg(
   data => '',
   slot => 2
);
$sign->addMsg(
   data => '',
   slot => 3
);
$sign->addMsg(
   data => '',
   slot => 4
);
$sign->addMsg(
   data => '',
   slot => 5
);
$sign->addMsg(
   data => '',
   slot => 6
);
$sign->addMsg(
   data => '',
   slot => 7
);
$sign->addMsg(
   data => '',
   slot => 8
);
$sign->send(
    device => "/dev/ttyUSB0"
#    baudrate => "9600",
#    packetdelay => 0.5
 );
