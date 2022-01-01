#! /usr/bin/perl

# cgadecode - convert CGA 640x200 Graphics Mode Memory Map to png

use strict;
use warnings;
use FindBin;
use Image::Magick;
use IO::File;

sub makePng($$);

die "usage: ${FindBin::Script} <input.pic> <output.png>\n" if 2 != @ARGV;

my $img = Image::Magick->new;

die unless ref($img);

makePng($img, $ARGV[0]);

$img->Write("$ARGV[1]");

exit;

################################################################################

sub makePng($$) {
   my $image = shift;
   die unless ref($image);

   my $inputFilename = shift;
   die unless "" ne $inputFilename;

   # create a new png
   my $width = 640;
   my $height = 200;
   $image->Set(size=>"640x200");
   $image->ReadImage('canvas:white');

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

      # There are 192 bytes of extra memory on each pass. 
      my $extra;
      sysread($inputFh, $extra, 192);
   }

   undef $inputFh;
}
