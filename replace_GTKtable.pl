#!/usr/bin/perl
use warnings;
use strict;

our $top;
our $left;
our $right;
our $width;
our $bottom;
our $height;
our $flagTOP =1;
our $flagLEFT =1;
our @zeilen = ();
my $arrSize;
my $i = 0;
my $flagInTable = 0;
my $flagPacking =0;
my $printpacking = 0;


# Oeffne Files zum Lesen bzw. zum Schreiben
my $input = $ARGV[0];
open EIN, "<$input" or die "Cant read $input: $!";
open AUS, ">test.txt" or die "Cant write $!";

# Schreibe das File zeilenweise in ein Array
@zeilen = <EIN>;
#print "@zeilen";
$arrSize = @zeilen;

while ( @zeilen[$i++] ) {

	# Ersetze GtkTable von invisiblestable mit VBox
	if ($zeilen[$i] =~ /invisiblestable/){
		$zeilen[$i] =~ s/GtkTable/GtkVBox/g;
	}

	# Wenn packing kein left-attach oder top-attach, dann fuege diese hinzu
	# Nur in erster Zeile oder erster Spalte der Fall.
	if ($zeilen[$i] =~ /<packing>/){
		$flagLEFT =1;
		$flagTOP =1;
	}
	if ($zeilen[$i] =~ '</packing>' && $flagTOP ==1){
		print AUS '<property name="top_attach">0</property>
';
		$flagTOP =0;		
	}
	if ($zeilen[$i] =~ '</packing>' && $flagLEFT ==1){
		print AUS '<property name="left_attach">0</property>
';
		$flagLEFT =0;
}

	# Ersetze GtkTable durch GtkGrid. Inkrementiere Tabellen-Flag
	if ($zeilen[$i] =~ /GtkTable/){
		$zeilen[$i] =~ s/GtkTable/GtkGrid/g;
		$flagInTable = 1;
	}
	# Fuer das Erste Element in der Tabelle, wenn kein packing vorhanden, fuege packing hinzu
	# Setze left-attach und top-attach dieses Objekts auf 0.
	if ($zeilen[$i] =~ '</object>' && $flagInTable == 1 && ($zeilen[$i+1] =~ /packing/) == 0){
		$printpacking =1;
	$flagInTable = 0;
	}

	# L;sche ueberfluessige Zeilen
	if ($zeilen[$i] =~ /x_options/ || $zeilen[$i] =~ /y_options/ ||
		$zeilen[$i] =~ /n_rows/ ||$zeilen[$i] =~ /n_columns/ )
	{
			$zeilen[$i] = ' ';
	}


	# Nehme Wert von top_attach
	if ($zeilen[$i] =~ /top_attach/){
		($top) = ($zeilen[$i] =~ /(\d+)/);
		print "top: $top\n";
		$flagTOP = 0;
	}
	# Nehme Wert von bottom_attach, berechne height und ersetze Zeile
	if ($zeilen[$i] =~ /bottom_attach/){
		($bottom) = ($zeilen[$i] =~ /(\d+)/);
		print "bottom: $bottom\n";
		$height = $bottom-$top;
		print "height: $height\n";
		$zeilen[$i] =~ s/bottom_attach/height/g;
		$zeilen[$i] =~ s/>(\d+)</>$height</g;
		$bottom = 0;
		$top =0;
	}
	# Nehme Wert von left_attach
	if ($zeilen[$i] =~ /left_attach/){
		($left) = ($zeilen[$i] =~ /(\d+)/);
		print "left: $left\n";
		$flagLEFT = 0;
	}
	# Nehme Wert von right_attach, berechne width und ersetze Zeile
	if ($zeilen[$i] =~ /right_attach/){
#		if ($left == NIL){$left = 0};
		($right) = ($zeilen[$i] =~ /(\d+)/);
		print "right: $right\n";
		$width = $right-$left;
		print "width: $width\n";
		$zeilen[$i] =~ s/right_attach/width/g;
		$zeilen[$i] =~ s/>(\d+)</>$width</g;
	}
	print AUS $zeilen[$i];
	# Schreibe fehlendes packing beim ersten Element in der Tabelle
	if ($printpacking == 1){
		print AUS '<packing>
	<property name="left_attach">0</property>
	<property name="top_attach">0</property>
</packing>
';
		$printpacking =0;
	}
}
close EIN;
close AUS;

# File ueberschreiben
unlink $input;
rename "test.txt", $input;

##!/bin/bash
#OLD="GtkTable"
#NEW="GtkGrid"
#DPATH="/home/eh/GeoParser/Geo/daten/adresse/*.glade"
#BPATH="/home/eh/GeoParser/Backup/daten/adresse"
#TFILE="/tmp/out.tmp.$$"
#[ ! -d $BPATH ] && mkdir -p $BPATH || :
#for f in $DPATH
#do
#  if [ -f $f -a -r $f ]; then
#    /bin/cp -f $f $BPATH
#    sed "s/$OLD/$NEW/g" "$f" > $TFILE && mv $TFILE "$f"
#  else
#    echo "ERROR: Cannot read $f"
#  fi
#done
#/bin/rm $TFILE

