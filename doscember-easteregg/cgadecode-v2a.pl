#! /usr/bin/perl

# cgadecode - convert CGA 640x200 Graphics Mode Memory Map to png
# Derek, Dec 31 2020

use strict;
use warnings;
use FindBin;
use Image::Magick;
use IO::File;

sub makePngWithBonus($$$);

################################################################################

die "usage: ${FindBin::Script} <input.pic> <output.png>\n" if 2 != @ARGV;

my $img = Image::Magick->new;
my $bonus = Image::Magick->new;

die unless ref($img);

makePngWithBonus($img, $bonus, $ARGV[0]);

$img->Write("$ARGV[1]");
$bonus->Write("bonus.png");

exit;

################################################################################

sub makePngWithBonus($$$) {
   my $image = shift;
   die unless ref($image);

   my $bonus = shift;
   die unless ref($bonus);

   my $inputFilename = shift;
   die unless "" ne $inputFilename;

   # create a new png
   my $width = 640;
   my $height = 200;
   $image->Set(size=>"640x200");
   $image->ReadImage('canvas:white');

   my $bWidth =  48;
   my $bHeight = 32;
   $bonus->Set(size=>"${bWidth}x${bHeight}");
   $bonus->set(colorspace => "RGB");
   $bonus->ReadImage('canvas:black');

   my $inputFh = IO::File->new($inputFilename, "r");
   die "open \"$inputFilename\" failed: $!\n" unless ref($inputFh);
   binmode($inputFh, ":bytes");

   my $row; # a bit vector representing each line/row

   foreach my $startY (0, 1) { # rows/lines are interlaced, so make two passes.
      for (my $y = $startY; $y < $height; $y += 2) {
	 sysread($inputFh, $row, 80); # read the 80 byte row
         # split it into bits
         my @bits = split(//,unpack("b*", $row));
         for (my $x = 0; $x < $width; $x++) {
	    # we have to reverse the bits in each byte because CGA:
            my $bit = !@bits[int($x / 8)*8+(7-($x % 8))];
	    $image->Set("pixel[$x,$y]" => ($bit,$bit,$bit));
	 }
      }

      # There are 192 bits of unused memory on each pass. 
      # Let's capture that memory.
      my $dummy;
      sysread($inputFh, $dummy, 192); # read the 192 bytes of unused space

      my @bits = split(//,unpack("b*", $dummy));

      for (my $y = 0; $y < $bHeight/2; $y++) {
          for (my $x = 0; $x < $bWidth; $x+=4) {
            my $rbit = @bits[$y*$bWidth+int($x / 8)*8+(7-($x % 8))]?'0':'f';
            my $gbit = @bits[$y*$bWidth+int(($x+1) / 8)*8+(7-(($x+1) % 8))]?'0':'f';
            my $bbit = @bits[$y*$bWidth+int(($x+2) / 8)*8+(7-(($x+2) % 8))]?'0':'f';
            my $xbit = @bits[$y*$bWidth+int(($x+3) / 8)*8+(7-(($x+3) % 8))]?'0':'f';
            my $xPixel = $x/4;
            my $yPixel = $startY * $bHeight / 2 + $y;
            $bonus->Set("pixel[$xPixel,$yPixel]" => "#$rbit$gbit$bbit")
          }
      }
   }

   undef $inputFh;
}
