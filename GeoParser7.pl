#!/usr/bin/perl
use strict;
use warnings;

use Switch;

use Path::Class;
use autodie; # die if problem reading or writing a file

#globale Variabel die für einen unbestimmten Widgetnamen verwendet wird.
our $widget = 0;
#globales Array in der der aktuelle Suchmodus gespeichert wird. (Bsp. dialog =
#Es wird nach Elemente für einen Dialog gesucht.)
our @searchMode = ();
our $preParent = '';
our @dialogContent = ();
our @contentTmp = ();

our @endLinie = ();
our @countVerElement = ();
our @countHorElement = ();
our @tagLevel = ();
our @result = ();
our @resultVer = ();
our @resultHor = ();

#globales Array zum speichern der Liniennummer auf der sich ein Dialog, Group
#etd. befindet.
our @lineNumber = ();

our @tableSizeHor = ();
our @tableSizeVer = ();

#globales Hash zum speichern der Dateinamen. Dateinamen = Wort nach dem dialog-
#Statement der geo-Datei. (key = Liniennummer)
our $fileName = '';

#our %fileName = ();
#globales Hash zum speichern der Tabellengrössen. (key = (Liniennummer -Ver) / 
#(Liniennummer -Hor))
our %tabelSize = ();

#Setzt das Schliessende interface-Tag in der xml-Datei
sub CloseTag{
  my $closing = "      </object>
    </child>
  </object>
</interface>";

    my $file = file($fileName);

    my $file_writing_handler = $file->open('>>');
  
    print $file_writing_handler $closing;

    close $file_writing_handler;
}

#Schreibt die xml-Dateien für den Builder.
#$_[0] = Liniennummer des dialog-Statements
#$_[1] = Dateiname der Quelldatei, worin die xml-Statements stehen.
#$_[2] = Aktuelle hor-Position des zu erstellenden Elements.
#$_[3] = Aktuelle ver-Position des zu erstellenden Elements.
#$_[4] = Die im Geo-File gelesene Zeile.
#$_[5] = Aktuelle Liniennummer des zu erstellenden Elements. Wird nur für 
#Tabellen verwendet um die Spalten- / Zeilenanzahl zu schreiben.
sub Write{
  my $counterHor = $_[1]- 1;
  my $counterVer = $_[2]- 1;
  my $geoLinie = $_[3];
  my $tableHor = $tabelSize { "$_[4] -Hor" };
  my $tableVer = $tabelSize { "$_[4] -Ver" };
  
  my @widgetName = ();
  my @widgetText = ();
  my @widgetHeightTmp1 = ();
  my @widgetHeightTmp2 = ();
  my @widgetWidthTmp1 = ();
  my @widgetWidthTmp2 = ();

  my $widgetHeight = 0;
  my $widgetWidth = 0;
  my $name = $widget;
  my $text = "";

  #print "$geoLinie";

  #Entfernt Whitespaces vor und nach dem Text (falls vorhanden).
  $geoLinie =~ s/^\s+|\s+$//g;
  
  @widgetName = split(' ', $geoLinie);  
  @widgetText = split('"', $geoLinie);

  #space getrennt
  #Setzt den Namen, er steht immer an 2. Stellle einer Linie und besteht aus 4 Zahlen.
  if (defined($widgetName[1])){
    if ($widgetName[1]  =~ /^\d{4}$/){
      $name = $widgetName[1];
    }
  }
  #double quotes getrennt
  #Setzt den Text, er steht immer an 2. Stellle einer Linie und besteht aus Buchstaben, Zahlen und :.
  if (defined($widgetText[1])){
    if ($widgetText[1] =~ /[A-Za-z0-9:]*$/){
      $text = $widgetText[1];
    }
  }

  #Sucht nach einer eckigen Klammer um darin die Breite und Hoehe des Widgets zu erhalten.
  if ($geoLinie =~ /\[/) {

    @widgetHeightTmp1 = split(' ', $geoLinie);

    foreach (@widgetHeightTmp1) {

      if ($widgetHeightTmp1[$widgetHeight] =~ /\]/) {
        last;
      }
      else {
        $widgetHeight++;
      }
    }

    if ($widgetHeightTmp1[$widgetHeight]) {

      $widgetHeightTmp1[$widgetHeight] =~ s/\[//g;
      $widgetHeightTmp1[$widgetHeight] =~ s/\]//g;

      @widgetHeightTmp2 = split(',', $widgetHeightTmp1[$widgetHeight]);
      
      if (defined($widgetHeightTmp2[1])){
        if ($widgetHeightTmp2[1] =~ /P/) {
          $widgetHeightTmp2[1] =~ s/P//g;
          $widgetHeightTmp2[1] =~ s/\0//g;
          $widgetHeight = $widgetHeightTmp2[1] * 2.5;
        }
        elsif ($widgetHeightTmp2[1] =~ /B/) {
          $widgetHeight = 0;
          #$widgetHeightTmp2[1] =~ s/\B//g;
          #$widgetHeight = $widgetHeightTmp2[1];
        }
        elsif ($widgetHeightTmp2[1] =~ /E/) {
          $widgetHeight = 0;
          #$widgetHeightTmp2[1] =~ s/\E//g;
          #$widgetHeight = $widgetHeightTmp2[1];
        }
        else {
          $widgetHeightTmp2[1] =~ s/\0//g;
          $widgetHeight = $widgetHeightTmp2[1] * 2.5;
        }
      }
      else {
        $widgetHeight = 0;
      }
    }

    @widgetWidthTmp1 = split(' ', $geoLinie);

    foreach (@widgetWidthTmp1) {

      if ($widgetWidthTmp1[$widgetWidth] =~ /\]/) {
        last;
      }
      else {
        $widgetWidth++;
      }
    }

    if ($widgetWidthTmp1[$widgetWidth]) {

      $widgetWidthTmp1[$widgetWidth] =~ s/\[//g;
      $widgetWidthTmp1[$widgetWidth] =~ s/\]//g;

      @widgetWidthTmp2 = split(',', $widgetWidthTmp1[$widgetWidth]);
      
      if (defined($widgetWidthTmp2[0])){
        $widgetWidth = $widgetWidthTmp2[0];
      }
      else {
        $widgetWidth = 0;
      }
    }
  }

  #Quelldatei im Modus read öffnen. (bla.xml)
  my $file_reader = file($_[0]);
  my $file_reader_handle = $file_reader->openr();

  #Zieldatei im Modus create + append öffnen. (blub.glade)
  my $file = file($fileName);
  my $file_writing_handler = $file->open('+>>');
  #Liest die Quelldatei zeilenweise.
  while ( my $linie = $file_reader_handle->getline() )
  {
    my $find = '';
    my $replace = '';
    
    #Ersetzt in der gelesenen Linie die Variabeln durch ihren Wert. Bsp.
    #$counterHor durch 5
    my $printLine = (eval "qq($linie)");
    if ($printLine =~ /left_attach/ || $printLine =~ /right_attach/ ||
      $printLine =~ /top_attach/ || $printLine =~ /bottom_attach/){
      if ($printLine =~ /0/ && $printLine =~ /10/ && $printLine =~ /20/){
        $printLine = '';
      }
    }
    #Ersetzt & durch _, da Windows & und Glade _ verwendet.
    if ($printLine =~ /&/ && $printLine !~ /&\w{2}[;]/){
      $find = "&";
      $replace = "_";
      $find = quotemeta $find;
      $printLine =~ s/$find/$replace/g;
    }

    #Ersetzt n_rows und n_columns durch nichts, wenn sie 1 sind, da sie ueberfluessig sind.
    if ($printLine =~ /n_rows/ || $printLine =~ /n_columns/){
      if ($printLine =~ /1/){
        $printLine = '';
      }
    }
    #Ersetzt height_request durch nichts, wenn es 0 ist.
    if ($printLine =~ /height_request/){
      if ($widgetHeight == 0){
        $printLine = '';
      }
    }
    #Ersetzt width... druch nichts, wenn es 0 ist.
    if ($printLine =~ /width_request/ || $printLine =~ /width_chars/){
      if ($widgetWidth == 0){
        $printLine = '';
      }
    }
    
    #Rechnet in der gelesenen Linie, sodass das einfügen von Zellen in Tabellen
    #funktioniert.
    if ($printLine =~ /^.*\+/){
      for ( my $i = 0; $i < 100; $i++){
        my $find = sprintf "%d + 1", $i;
        my $replace = sprintf "%d", $i + 1;
        $find = quotemeta $find;
        $printLine =~ s/$find/$replace/g;
      }
    }
    #Schreibt die evtl. bearbeitete Linie in die Datei.
    print $file_writing_handler $printLine;
  }
  #Schliesst die Dateien.
  close $file_reader_handle;
  close $file_writing_handler;

  #Zählt ein "verwendetes" Widget dazu.
  $widget++;
}

#Ermittelt, welches Element erstellt werden muss.
#$_[0] = File-Handle
#$_[1] = in der der aktuelle Suchmodus gespeichert wird. (Bsp. dialog = Es wird
#nach Elemente für einen Dialog gesucht.)
#$_[2] = Liniennummer des dialog-Statements
sub CreateXML_old{
  my $file_reading_handler = $_[0];
  my $parentMode = $_[1];
  my $dialogLinie = $_[2];

  #Variabel zum speichern der aktuellen Liniennummer.
  my $linienNummer;
  #Variabeln mit den aktuellen Positionen.
  my $counterHor = 0;
  my $counterVer = 0;
  
  #Liest die Geo zeilenweise und ermittelt das zu erstellende Element.
  while ( my $linie = $file_reading_handler->getline() )
  {
    $linie =~ s/\0//g;
    #Erhält die aktuelle Liniennummer.
    $linienNummer = $file_reading_handler->input_line_number();
    #Überspringt Leerzeilen
    if ($linie =~ /^\s$/){
      next;
    }
    #Überspringt skript und help anweisungen.
    if ($linie =~ /^\s*skript/ || $linie =~ /^\s*help/) {
      push @searchMode, 'skip';
      CreateXML($file_reading_handler, 'skip', $dialogLinie);
    }
    #Erstellt einen Dialog.
    if ($linie =~ /^\s*dialog/) {
      #Setzt den Suchmodus.
      push @searchMode, 'dialog';
      push @tableSizeHor, $counterHor;
      push @tableSizeVer, $counterVer;
      ##########################################################################
      #print $file_reading_handler->input_line_number() . "\n";                #
      ##########################################################################
      $dialogLinie = $file_reading_handler->input_line_number();
      ##########################################################################
      #print $dialogLinie . "\n";                                              #
      #print $file_reading_handler->input_line_number() . "\n";                #
      ##########################################################################
      #Ruft Write auf um eine neue Datei zu erstellen und einen neuen Dialog.
      Write($dialogLinie, "Dialog.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
      #Ruft sich selbst wieder auf.
      CreateXML($file_reading_handler, 'dialog', $dialogLinie);
    }
    #Zählt eine Zeile / Spalte dazu, sofern es sich um ein zu zählendes Element
    #handelt.
    if ($linie !~ /^\s*space/ && $linie !~ /^\s*xstandard/ &&
      $linie !~ /^\s*taborder/ && $linie !~ /^\s*MENU/ && $linie !~ /^\s*end/ &&
      $parentMode ne 'skip') {
      if ($parentMode ne 'hor') {
        if ($counterHor == 0) {
          $counterHor++;
        }
        $counterVer++;
      }
      else
      {
        if ($counterVer == 0) {
          $counterVer++;
        }
        $counterHor++;
      } 
    }
    #Erstellt eine Gruppe
    if ($linie =~ /^\s*group/) {
      push @searchMode, 'group';
      push @tableSizeHor, $counterHor;
      push @tableSizeVer, $counterVer;
      Write($dialogLinie, "Group.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
      CreateXML($file_reading_handler, 'group', $dialogLinie);
    }
    if ($linie =~ /^\s*frame/) {
      push @searchMode, 'frame';
      push @tableSizeHor, $counterHor;
      push @tableSizeVer, $counterVer;
      Write($dialogLinie, "Frame.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
      CreateXML($file_reading_handler, 'frame', $dialogLinie);
    }
    if ($linie =~ /^\s*hor/) {
      push @searchMode, 'hor';
      push @tableSizeHor, $counterHor;
      push @tableSizeVer, $counterVer;
      Write($dialogLinie, "VerHor.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
      CreateXML($file_reading_handler, 'hor', $dialogLinie);
    }
    if ($linie =~ /^\s*ver/) {
      push @searchMode, 'ver';
      push @tableSizeHor, $counterHor;
      push @tableSizeVer, $counterVer;
      Write($dialogLinie, "VerHor.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
      CreateXML($file_reading_handler, 'ver', $dialogLinie);
    }
    if ($linie =~ /^\s*text/) {
      Write($dialogLinie, "Label.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*edit/) {
      if ($linie =~ /^\s*editml/) {
        Write($dialogLinie, "Textview.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
      else
      {
        Write($dialogLinie, "Entry.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
    }
    if ($linie =~ /^\s*show/) {
      Write($dialogLinie, "Show.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*line/) {
      if ($parentMode eq 'hor') {
        Write($dialogLinie, "LineH.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
      if ($parentMode eq 'ver') {
        Write($dialogLinie, "LineV.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
    }
    if ($linie =~ /^\s*fill/) {
      Write($dialogLinie, "Fixed.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*combo/) {
      Write($dialogLinie, "Combo.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*check/) {
      Write($dialogLinie, "Check.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*radio/) {
      Write($dialogLinie, "Radio.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*image/) {
      Write($dialogLinie, "Image.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*empty/) {
      Write($dialogLinie, "Empty.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*button/) {
      Write($dialogLinie, "Button.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*graphic/) {
      Write($dialogLinie, "DrawingArea.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*sftlist/) {
      Write($dialogLinie, "List.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*control/) {
      if ($parentMode eq 'hor') {
        Write($dialogLinie, "ScrollbarH.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
      if ($parentMode eq 'ver') {
        Write($dialogLinie, "ScrollbarV.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
    }
    if ($linie =~ /^\s*grbutton/) {
      Write($dialogLinie, "Button.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*invisible/) {
      Write($dialogLinie, "Invisible.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    if ($linie =~ /^\s*defbutton/) {
      Write($dialogLinie, "Button.xml", $counterHor, $counterVer, $linie,
        $linienNummer);
    }
    #Geht eine Stufe zurück.
    if ($linie =~ /^\s*end/) {
      if ($parentMode ne 'skip') {
        $counterHor = pop @tableSizeHor;
        $counterVer = pop @tableSizeVer;
        print "$dialogLinie\t\t$counterHor\t\t$counterVer\t\t$linienNummer\t\t
        $parentMode\t\t$linie";
        if ($parentMode eq 'group' || $parentMode eq 'frame') {
          Write($dialogLinie, "End.xml", 1, 1, $linie, $linienNummer);
        }
        Write($dialogLinie, "End.xml", $counterHor, $counterVer, $linie,
          $linienNummer);
      }
      $parentMode = pop @searchMode;
      return;
    }
  }
}

#Befüllt das FileName-Hash.
#$_[0] = File-Handle
sub CreateFileName{
  $fileName = $_[0];

  my $find = sprintf ".dlg";
  my $replace = sprintf ".glade";
  
  $find = quotemeta $find;
  
  $fileName =~ s/$find/$replace/g;
}

#Zählt die benötigten Zeilen und Spalten.
#$_[0] = File-Handle
#$_[1] = in der der aktuelle Suchmodus gespeichert wird. (Bsp. dialog = Es wird
#nach Elemente für einen Dialog gesucht.)
sub SaveInArray{
  my $file_handler = $_[0];
  my $inDialog = $_[1];
  my $level = $_[2];

  #Liest die Geo zeilenweise...
  while ( my $linie = $file_handler->getline() ) {
    $linie =~ s/\0//g;
    #print "$linie";
    
    if ($linie =~ /^\s*dialog/i) {
      push @dialogContent, $linie;
      push @endLinie, 0;
      push @countVerElement, 0;
      push @countHorElement, 0;
      push @tagLevel, $level;
      SaveInArray($file_handler, 1, $level + 1);
    }
    elsif($inDialog != 1 || $linie =~ /^\s*xstandard/i || $linie =~ /^\s$/i ||
      $linie =~ /^\s*space/i || $linie =~ /^\s*taborder/i) {
      next;
    }
    else{
      my $Content = "";
      for (my $i = 0; $i < (($linie =~ /^\s*end/i) ? ($level -1) : $level); $i++){
        $Content = "\t$Content";
      }
      push @dialogContent, "$Content$linie";
      push @endLinie, 0;
      push @countVerElement, 0;
      push @countHorElement, 0;
      if ($linie =~ /^\s*end/i) {
        push @tagLevel, ($level - 1);
      }
      else {
        push @tagLevel, $level;
      }
        
      if ($linie =~ /^\s*group/i || $linie =~ /^\s*frame/i ||
           $linie =~ /^\s*hor/i || $linie =~ /^\s*ver/i){
        $level = SaveInArray($file_handler, 1, $level + 1);
      }
      elsif ($linie =~ /^\s*end/i) {
        if ($level - 1 < 0) {
          last;
        }
        else
        {
          return ($level - 1);
        }
      }
    }
  }
}

sub CountTable{
  my $readPosition = $_[0];
  my $parentMode = $_[1];
  my $startline = $_[2];

  my $counterHor = 0;
  my $counterVer = 0;

  #Liest die Geo zeilenweise...
  while ( defined($dialogContent[$readPosition]) ) {
    my $linie = $dialogContent[$readPosition];
    $readPosition = $readPosition + 1;

    if ($linie =~ /^\s*dialog/i) {
      $readPosition = CountTable($readPosition, 'dialog', $readPosition-1);
    }
    if ($linie !~ /^\s*end/i){
      if ($parentMode ne 'hor') {
        if ($counterHor == 0) {
          $counterHor++;
        }
        $counterVer++;
      }
      else
      {
        if ($counterVer == 0) {
          $counterVer++;
        }
        $counterHor++;
      } 
    }

    #print "$linie";
    #print "VER:\t$counterVer\nHOR:\t$counterHor\n";

    if ($linie =~ /^\s*group/i) {
      $readPosition = CountTable($readPosition, 'group', $readPosition-1);
    }
    if ($linie =~ /^\s*frame/i) {
      $readPosition = CountTable($readPosition, 'frame', $readPosition-1);
    }
    if ($linie =~ /^\s*hor/i) {
      $readPosition = CountTable($readPosition, 'hor', $readPosition-1);
    }
    if ($linie =~ /^\s*ver/i) {
      $readPosition = CountTable($readPosition, 'ver', $readPosition-1);
    }
    if ($linie =~ /^\s*end/i) {
      #print "-----\nPARENT:\t$parentMode\nLINIESTART:\t$startline\n";
      #print "LINIESTOP:\t($readPosition-1)\nVER:\t$counterVer\n";
      #print "HOR:\t$counterHor\n----\n";
      my $Element = pop @lineNumber;
      #Schreibt die benötigten Zeilen / Spalten in das Hash.
      $tabelSize { "$startline -Ver" } = "$counterVer";
      $tabelSize { "$startline -Hor" } = "$counterHor";
      $endLinie[$startline] = ($readPosition - 1);
      $countVerElement[$startline] = $counterVer;
      $countHorElement[$startline] = $counterHor;

      return $readPosition;
    }
  }
}

sub CreateXML{
  my $readPosition = $_[0];
  my $parentMode = $_[1];
  my $startline = $_[2];
  my $customTable = $_[3];

  my $counterHor = $_[4];
  my $counterVer = $_[5];

#
#   Logik
#
#   Wenn dialog, group, frame, hor oder ver vorkommt, im Array
#   @endLine die end-Liniennummer auslesen und mithilfe einer
#   for-Schlaufe herausfinden, ob in countVer / countHor zwischen
#   readPosition und end 2 oder mehr gleiche Zahlen vorkommen
#   (ausser 0). Wenn dem so ist wird die Tabelle mit der Zahl
#   der übereinstimmungen erstellt.
#   Bsp:
#   hor mit 2 Elementen
#     ver mit 8 Elementen
#     end
#     ver mit 8 Elementen
#     end
#   end
#
#   hor wird mit 2 Spalten und 8 Zeilen erstellt.


  #Liest die Geo zeilenweise...
  while ( defined($dialogContent[$readPosition]) ) {
    my $linie = $dialogContent[$readPosition];
    $readPosition = $readPosition + 1;
################################
#Werden in SaveInArray erstellt und in CountTable befuellt
#our @endLinie = ();
#our @countVerElement = ();
#our @countHorElement = ();
#our @tagLevel = ();
################################
#our @resultVer = ();
#our @resultHor = ();
################################

    while(scalar(@resultHor) != 0) {
      pop(@resultHor);
    }
    while(scalar(@resultVer) != 0) {
      pop(@resultVer);
    }

#Sucht nach Elementen eines tags, die die gleiche Groesse haben, ist dem so, wird
#customTabel auf 1 gesetzt, andernfalls wird customTabel auf 0 gesetzt. 
    my $i;
    for ($i = ($readPosition - 1); $i < $endLinie[($readPosition - 1)]; $i++) {
      if ($tagLevel[$i] == ($tagLevel[($readPosition - 1)] + 1)) {
        if ($countHorElement[$i] != 0 || $countVerElement[$i] != 0) {
#          print "\n" . "($readPosition-1), i = $i\t" . $linie;
          if ($countHorElement[$i] != 0 && $countHorElement[$i] != 1) {
#            print "HOR:\t" . $countHorElement[$i] . "\n";
            push @resultHor, $countHorElement[$i];
          }
          if ($countVerElement[$i] != 0 && $countVerElement[$i] != 1) {
#            print "VER:\t" . $countVerElement[$i] . "\n";
            push @resultVer, $countVerElement[$i];
          }
        }
      }
    }
    $i = 0;
    while(defined($resultHor[$i + 1])) {
      if ( $resultHor[$i] == $resultHor[$i + 1]) {
        $customTable = 1;
        print "$readPosition HOR extended" . $linie;
      }
      $i++;
    }
    $i = 0;
    while(defined($resultVer[$i + 1])) {
      if ( $resultVer[$i] == $resultVer[$i + 1]) {
        $customTable = 1;
        print "$readPosition VER extended" . $linie;
      }
      $i++;
    }
    if (!defined($resultHor[0]) && !defined($resultVer[0])) {
      $customTable = 0;
    }

#    print $customTable . "\t" . $linie;

#Prueft, ob sich ein dialog-tag in linie befindet. und steht vor dem Zaehlen, da Dialog immer das
#erste Element ist.
    if ($linie =~ /^\s*dialog/i) {
      print "$readPosition \t\tHOR: \t $counterHor\n";
      print "$readPosition \t\tVER: \t $counterHor\n";
      Write("Dialog.xml", $counterHor, $counterVer, $linie, $readPosition - 1);
      #
      #
      #
      #Wenn customTable 1 ist, soll bei der darunterliegenden Ebene bei allen Elementen
      #in hor und ver nach 1 die Position um 1 erhoeht werden. (Funktioniert in der jetzigen
      #Umsetzung nicht.)
      #Bsp:
      # hor
      #   ver
      #      text "bla"
      #   end
      #   ver
      #     text "blub"
      #   end
      # end
      # 
      # text "bla" erhaelt die Position 1 : 1 in hor, text "blub" erhaelt die Position 1 : 2
      #////
      #
      #
      if ($customTable == 0){
        $readPosition = CreateXML($readPosition, 'dialog', $readPosition-1, $customTable, 0, 0);
      }
      else {
        $readPosition = CreateXML($readPosition, 'dialog', $readPosition-1, $customTable, $counterHor, 0);
      }
    }
    #Wenn kein end in linie steht, wird entsprechend dem parent ver oder hor erweitert.
    #Ist es das erste Element einer Tabelle so werden ver und hor erweitert
    if ($linie !~ /^\s*end/i){
      if ($parentMode ne 'hor') {
        if ($counterHor == 0) {
          $counterHor++;
        }
        $counterVer++;
      }
      else
      {
        if ($counterVer == 0) {
          $counterVer++;
        }
        $counterHor++;
      } 
    }
    print "$readPosition \t\tHOR: \t $counterHor\n";
    print "$readPosition \t\tVER: \t $counterVer\n";

    #Analog dialog
    if ($linie =~ /^\s*group/i) {
      if ($customTable == 0){
        $readPosition = CreateXML($readPosition, 'group', $readPosition-1, $customTable, 0, 0);
      }
      else {
        $readPosition = CreateXML($readPosition, 'group', $readPosition-1, $customTable, $counterHor, 0);
      }
    }
    if ($linie =~ /^\s*frame/i) {
      if ($customTable == 0){
        $readPosition = CreateXML($readPosition, 'frame', $readPosition-1, $customTable, 0, 0);
      }
      else {
        $readPosition = CreateXML($readPosition, 'frame', $readPosition-1, $customTable, $counterHor, 0);
      }
    }
    if ($linie =~ /^\s*hor/i) {
      if ($customTable == 0){
        $readPosition = CreateXML($readPosition, 'hor', $readPosition-1, $customTable, 0, 0);
      }
      else {
        $readPosition = CreateXML($readPosition, 'hor', $readPosition-1, $customTable, $counterHor, 0);
      }
    }
    if ($linie =~ /^\s*ver/i) {
      if ($customTable == 0){
        $readPosition = CreateXML($readPosition, 'ver', $readPosition-1, $customTable, 0, 0);
      }
      else {
        $readPosition = CreateXML($readPosition, 'ver', $readPosition-1, $customTable, 0, $counterVer);
      }
    }
    #if fuer alle anderen Elemente zu erstellen, siehe CreateXML_old()
    if ($linie =~ /^\s*text/i) {
      Write($dialogLinie, "../Label.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*edit/i) {
      if ($linie =~ /^\s*editml/) {
        Write($dialogLinie, "../Textview.xml", $counterHor, $counterVer, $linie, $linienNummer);
      }
      else
      {
        Write($dialogLinie, "../Entry.xml", $counterHor, $counterVer, $linie, $linienNummer);
      }
    }
    if ($linie =~ /^\s*show/i) {
      Write($dialogLinie, "../Show.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*line/i) {
      if ($parentMode eq 'hor') {
        Write($dialogLinie, "../LineH.xml", $counterHor, $counterVer, $linie, $linienNummer);
      }
      if ($parentMode eq 'ver') {
        Write($dialogLinie, "../LineV.xml", $counterHor, $counterVer, $linie, $linienNummer);
      }
    }
    if ($linie =~ /^\s*fill/i) {
      Write($dialogLinie, "../Fixed.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*combo/i) {
      Write($dialogLinie, "../Combo.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*check/i) {
      Write($dialogLinie, "../Check.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*radio/i) {
      Write($dialogLinie, "../Radio.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*image/i) {
      Write($dialogLinie, "../Image.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*empty/i) {
      Write($dialogLinie, "../Empty.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*button/i) {
      Write($dialogLinie, "../Button.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*graphic/i) {
      Write($dialogLinie, "../DrawingArea.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*sftlist/i) {
      Write($dialogLinie, "../List.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*control/i) {
      if ($parentMode eq 'hor') {
        Write($dialogLinie, "../ScrollbarH.xml", $counterHor, $counterVer, $linie, $linienNummer);
      }
      if ($parentMode eq 'ver') {
        Write($dialogLinie, "../ScrollbarV.xml", $counterHor, $counterVer, $linie, $linienNummer);
      }
    }
    if ($linie =~ /^\s*grbutton/i) {
      Write($dialogLinie, "../Button.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*invisible/i) {
      Write($dialogLinie, "../Invisible.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*defbutton/i) {
      Write($dialogLinie, "../Button.xml", $counterHor, $counterVer, $linie, $linienNummer);
    }
    if ($linie =~ /^\s*end/i) {
      return $readPosition;
    }
  }
}
#Liest die Geo-Datei, die mit dem einem Argument übergeben wurde.
my $file_read = file($ARGV[0]);
my $file_read_handle = $file_read->openr();

#Ruft CreateFileName mit den benötigten Argumenten auf.
CreateFileName($ARGV[0]);

print "$ARGV[0]\n";
print "$fileName\n";

#Ruft CountTabel mit den benötigten Argumenten auf.
SaveInArray($file_read_handle, 0 ,0);
close $file_read_handle;
CountTable(0, '', 0);
CreateXML(0, '', 0, 0, 0, 0);

#Ruft CreateXML mit den benötigten Argumenten auf.
#CreateXML_old($file_read_handle, '');
################################################################################
foreach my $key (sort (keys(%tabelSize))) {                                    #
   print "$key\t\t$tabelSize{$key}\n";                                         #
}                                                                              #
#while ( my ($key, $value) = each(%fileName) ) {                               #
#  print "$key => $value\n";                                                   #
#}                                                                             #
my $i = 0;                                                                     #
#foreach (@dialogContent) {                                                    #
#  if ( $i < 10) {                                                             #
#    print $i . "\t\t\t" . $_;                                                 #
#  }                                                                           #
#  else {                                                                      #
#    print $i . "\t\t" . $_;                                                   #
#  }                                                                           #
#  $i++;                                                                       #
#}                                                                             #
#$i = 0;                                                                       #
#foreach (@countVerElement) {                                                  #
#  print "Ver\t" . $i . "\t" . $_ . "\n";                                      #
#  $i++;                                                                       #
#}                                                                             #
#$i = 0;                                                                       #
#foreach (@countHorElement) {                                                  #
#  print "Hor\t" . $i . "\t" . $_ . "\n";                                      #
#  $i++;                                                                       #
#}                                                                             #
#$i = 0;                                                                       #
#foreach (@endLinie) {                                                         #
#  if ( $i < 10) {                                                             #
#    print "tag\t" . $i . "\t\t" . $_ . "\n";                                  #
#  }                                                                           #
#  else {                                                                      #
#  print "tag\t" . $i . "\t" . $_ . "\n";                                      #
#  }                                                                           #
#  $i++;                                                                       #
#}                                                                             #
#$i = 0;                                                                       #
#foreach (@tagLevel) {                                                         #
#  if ( $i < 10) {                                                             #
#    print "tag\t" . $i . "\t\t" . $_ . "\n";                                  #
#  }                                                                           #
#  else {                                                                      #
#  print "tag\t" . $i . "\t" . $_ . "\n";                                      #
#  }                                                                           #
#  $i++;                                                                       #
#}                                                                             #
################################################################################

#Ruft CloseTag auf um die Dateien zu vollenden.
CloseTag();

