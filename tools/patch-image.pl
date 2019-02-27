#!/usr/bin/env perl

#
# Patch  the official  MINIX3 ISO  installer image  to use  the serial
# console.
#
# This script does not really understand the ISO9660 format and simply
# does a  pattern search in the  file for the beginning  and ending of
# well-known markers ($marker_start, $marker_end, below)
#
# Blame (most) bugs on: Martin Kjellstrand <martin.kjellstrand@madworx.se>

use strict;
use warnings;
use Carp qw( croak );

my $marker_start = "banner=Welcome";
my $marker_end   = "\n\0";

my $BUFSIZE=3;       # Number of $BLOCKSIZE blocks the complete buffer will contain.
my $BLOCKSIZE=16384; # Read up to this many bytes at a time

my $iso_fh;

open( $iso_fh, "+<", shift ) or croak "open(): ".$!;
patch_iso( $iso_fh );
close $iso_fh;

sub patch_iso {
    my $buffer_head_offset = 0; # Byte offset into the .ISO image, where the start of the buffer is.
    my @buffer    = ();     # Array of <= $BUFSIZE byte elements.
    my $pos_start = -1;     # Byte offset in ISO image of <start marker>.
    my $pos_end   = -1;     # Byte offset in ISO image of end of <end marker>.

    my $fh     = shift;
    my $break  = 0;
    do {
        my $buf;
        read( $fh, $buf, $BLOCKSIZE );
        push( @buffer, $buf );
        my $fullbuf = join( "", @buffer );

        if ( $pos_start == -1 ) {
            my $pos_start_rel = index($fullbuf,$marker_start);
            if ( $pos_start_rel != -1 ) {
                $pos_start = $pos_start_rel + $buffer_head_offset;
            }
        } else {
            my $pos_end_rel = index( $fullbuf, $marker_end, $pos_start-$buffer_head_offset );
            if ( $pos_end_rel != -1 ) {
                $pos_end = ($pos_end_rel + $buffer_head_offset) + (length $marker_end) - 1;
                $break = 1;
            }
        }

        while ( scalar @buffer > $BUFSIZE ) {
            $buffer_head_offset += length shift @buffer;
        }

        croak "Error: Read until EOF of image without finding start or ending marker."
            if eof( $fh );

    } while( !$break );

    my $boot_conf;
    my $file_length = ($pos_end-$pos_start);

    print "Reading ".$file_length." bytes of boot.conf\n";

    seek( $fh, $pos_start, 0 );
    if ( read( $fh, $boot_conf, $file_length ) != $file_length ) {
        croak "read wrong number of bytes from iso."
    }

    #print "Dumping original contents:\n";
    #print "====================================================\n";
    #print $boot_conf;
    #print "====================================================\n";

    (my $newconf = $boot_conf) =~ s/^(menu=Regular.*)/$1 console=tty00/mgx;

    my $slice_off = length($newconf)-length($boot_conf);
    print "Slicing off ".$slice_off." bytes from banner.\n";
    $newconf =~ s/^(banner=)={$slice_off}/$1/mgx;
    $boot_conf = substr( $newconf, 0, $file_length - 1 )."\n";
    print "Writing patched boot.cfg:\n";
    print "====================================================\n";
    print $boot_conf;
    print "====================================================\n";

    seek $fh, $pos_start, 0;
    print $fh $boot_conf;
    return;
}
