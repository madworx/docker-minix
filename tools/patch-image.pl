#!/usr/bin/env perl

use strict;
use warnings;
use Carp qw( croak );

my $marker_start = "banner=Welcome";
my $marker_end   = "# This space intentionally left blank - leave to appease bootloader!\n\0";

my $BUFSIZE=3;
my $BLOCKSIZE=16384;

my $bufhead   = 0;
my @buffer    = ();
my $pos_start = -1;
my $pos_end   = -1;

my $iso_fh;

open( $iso_fh, "+<", shift ) or croak "open(): ".$!;
patch_iso( $iso_fh );
close $iso_fh;

sub patch_iso {
    my $fh = shift;
    my $break     = 0;
    do {
        my $buf;
        read( $fh, $buf, $BLOCKSIZE );
        push( @buffer, $buf );
        my $fullbuf = join( "", @buffer );
        
        if ( $pos_start == -1 ) {
            if ( index( $fullbuf, $marker_start ) != -1 ) {
                $pos_start = (index($fullbuf,$marker_start) + $bufhead);
            }
        } else {
            if ( index( $fullbuf, $marker_end ) != -1 ) {
                $pos_end = (index($fullbuf,$marker_end) + $bufhead) + (length $marker_end) - 1;
                $break = 1;
            }
        }
        
        while ( scalar @buffer > $BUFSIZE ) {
            $bufhead += length shift @buffer;
        }
        
        croak "Error: Read until EOF of image without finding start or ending marker." 
            if eof( $fh );
        
    } while( !$break );
   
    my $boot_conf;
    my $file_length = ($pos_end-$pos_start);
    seek( $fh, $pos_start, 0 );
    if ( read( $fh, $boot_conf, $file_length ) != $file_length ) {
        croak "read wrong number of bytes from iso."
    }
    
    #print "Dumping contents:\n";
    #print "====================================================\n";
    #print $boot_conf;
    #print "====================================================\n";
    
    (my $newconf = $boot_conf) =~ s/^(menu=Regular.*)/$1 console=tty00/mgx;
    $boot_conf = substr( $newconf, 0, $file_length - 1 )."\n";
    print "Writing patched boot.cfg:\n";
    print "====================================================\n";
    print $boot_conf;
    print "====================================================\n";
    
    seek $fh, $pos_start, 0;
    print $fh $boot_conf;
    return;
}
