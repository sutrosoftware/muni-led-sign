#!/usr/bin/perl -w
# This script simply udpates the sign with more data.  If you need to write a
# more sophisticated client, just call this file from somewhere else.

use strict qw(subs vars);
use warnings;
use Device::MiniLED;
my $sign=Device::MiniLED->new(devicetype => "sign");
my $pic = $sign->addPix(clipart => "zen16");
$sign->addMsg(
   data => "Hello $pic",
   effect => 'hold',
   slot => 1
);
$sign->send(
      device => "/dev/ttyUSB0"
      #packetdelay => 0.5
      #baudrate => "9600"
      #debug => "true"
);
