#!/usr/bin/perl
#
# Liest exportierte Datenpunkte ein und erzeugt eine
# Karteikasten-Importdatei mit konvertierten Variablen
# 8 und 9, bei denen von der Meldungsgruppe nur noch
# die Identifikation gespeichert ist.
#
# Aufruf:
#  perl fdspunkt.pl <Inputfile> <Outputfile>
#

$eindatei = $ARGV[0];
$ausdatei = $ARGV[1];
$count = 0;

open( EIN, "<$eindatei" ) or die "Kann $eindatei nicht oeffnen: $!\n";
open( AUS, ">$ausdatei" ) or die "Kann $ausdatei nicht anlegen: $!\n";

while ( $zeile = <EIN> )
{
  chomp( $zeile );

  if ( $zeile =~ /(.{3})\s+(.+)/ )
  {
    if ( $1 eq "  8" || $1 eq "  9" )
    {
      if ( length($2) > 40 )
      {
        $bezeichnung = substr( $2, 0, 40 );      # an Pos 40 abschneiden
        $bezeichnung =~ s/\s+$//;                # Leerschläge am Ende weg
      }
      $zeile = $1 . " " . $bezeichnung;
    }
  }
    printf AUS "%s\n", $zeile;
}
close( EIN );
close( AUS );