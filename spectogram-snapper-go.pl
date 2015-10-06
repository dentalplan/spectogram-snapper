#!/usr/bin/perl -w

# Spectogram snapper
# Written by Cliff Hammett
# Built on top of:
# | Perl/Tk Webcam Streamer and Snapshot Taker
# | Proof of Concept
# | Author: Casey Kirsle, http://www.cuvou.com/
# At time of writing, his program can be found here: http://www.perlmonks.org/?node_id=792758
#
# Published under GPL v2

use strict;
use warnings;
use Tk;
use Tk::JPEG;
use MIME::Base64 "encode_base64";
use specsnap_dispcontrol;
use gm_testtools;
use GD;
use GD::Tiler;
#use open qw/:std :utf8/;

#set up my disp control module
my $disp = new specsnap_dispcontrol;
my $test = new gm_testtools;
# Some things that might need to be configured.
my $device = shift(@ARGV) || "/dev/video0";
if ($device =~ /^\// && !-e $device) {
	die "Can't see video device: $device";
}

my $continuous = {switch=>0, grabon=>0, active=>0}; #this variable determines if it takes a cont image
$continuous->{count} = $continuous->{grabon};

# Tk MainWindow
my $mw = MainWindow->new (
	-title => 'Tk Stream',
);
$mw->protocol (WM_DELETE_WINDOW => \&onExit);

#Set up entries
my $rh_entryvalue = &setUpEntries;

my $rh_buttons = &setUpButtons;
# A label to display the photos.
my $photo = $mw->Label ()->pack();
my $mode_label =  $mw->Label ()->pack();
#my @photoset = ($mw->Label ()->pack(),
#		$mw->Label ()->pack(),
#		$mw->Label ()->pack(),
#		$mw->Label ()->pack(),
#		$mw->Label ()->pack());

#set up buttons;

# An array of images created
my @imageset = ();

# A button to capture a photo

$mw->update();

#my $cmd = "ffmpeg -b 100K -an -f video4linux2 -s 320x240 -r 10 -i $device -b 100K -f image2pipe -vcodec mjpeg - "
#	. "| perl -pi -e 's/\\xFF\\xD8/KIRSLESEP\\xFF\\xD8/ig'";
my $cmd = "ffmpeg -an -f video4linux2 -s 320x240 -r 10 -i $device -b 100K -f image2pipe -vcodec mjpeg - "
	. "| perl -pi -e 's/\\xFF\\xD8/KIRSLESEP\\xFF\\xD8/ig'";
open (PIPE, "$cmd |");

my ($image,$lastimage);

my $i = 0;
my $jpgBuffer = ""; # last complete jpg image
my $buffer = ""; # bytes read
my $lastFrame = ""; # last complete jpg (kept until another full frame was read; for capturing to disk)
my $display = ""; #variable for jpg data that will be displayed
my $mode_text = 'normal';
while (read(PIPE, $buffer, 2048)) {
	my (@images) = split(/KIRSLESEP/, $buffer);
	shift(@images) if length $images[0] == 0;
	if (scalar(@images) == 1) {
		# Still the old image.
		my $len = length $images[0];
		$jpgBuffer .= $images[0];
	}
	elsif (scalar(@images) == 2) {
		# We've completed the old image.
		$jpgBuffer .= shift(@images);
		my $len = length $images[0];
		next if length $jpgBuffer == 0;

		# Put this into the last frame received, in case the user
		# wants to save this snapshot to disk.
		$lastFrame = $jpgBuffer;

		if ($continuous->{switch} == 1){
			$continuous->{count}++;
		#	print "counting.... " . $continuous->{count} . "... ";
			if ($continuous->{count} >= $continuous->{grabon}){
				&takeFrame;
				$continuous->{count} = 0;
			#	print "\n";
				$mode_text="Recording strips";
	#			my $img = &tileImageStrips;
	#			$display = $img->jpeg;
			}
		}else{
			$mode_text = 'normal'
		}
		# Create a new Photo object to hold the jpeg
		$display = $jpgBuffer;
		eval {
			$image = $mw->Photo (
				-data => encode_base64($display),
				-format => 'JPEG',
			);
		};
		# Update the label to display the snapshot
		eval {
			$photo->configure (-image => $image);
			$mode_label->configure(-text=>$mode_text);
		};
		# Delete the last image to free up memory leaks,
		# then copy the new image to it.
		$lastimage->delete if ($lastimage);
		$lastimage = $image;

		# Refresh the GUI
		$mw->update();

		# Start reading the next image.
		$jpgBuffer = shift(@images);
	}
	else {
		print "Weird error: 3 items in array!\n";
		exit(1);
	}
}

sub snapshot {
	# Make up a capture filename.
#	my $i = 0;
#	my $fname = "capture" . (sprintf("%04d",$i)) . ".jpg";
#	while (-f $fname) {
#		$fname = "capture" . (sprintf("%04d",++$i)) . ".jpg";
#	}
	if ($continuous->{switch} == 0){
		&takeFrame;
	}else{
		print "No pic taken when cont mode on\n";
	}
#	$test->printRefArray(\@imageset);
}

sub takeFrame{
	my $fname = 'capturebuffer.jpg';
	# Save it.
	open (WRITE, ">$fname");
	binmode WRITE;
	print WRITE $lastFrame;
	close (WRITE);
	print "Frame capture saved as $fname\n";
	my $gd = GD::Image->newFromJpeg($fname);
	push (@imageset, $gd);
}

sub makeIntoStrip{
	my $gd = shift;
	my ($width, $height) = $gd->getBounds();
	my $stripwidth = int($width / 32);
	my $strip = GD::Image->new($stripwidth,$height);
	$strip->copy($gd, 0,0,($width/2)-($stripwidth/2),0,$stripwidth, $height);
	return $strip;
}

sub onExit {
	# Close ffmpeg.
	print "Exiting!\n";
	close (PIPE);
}

sub setUpEntries{
	my $frame = $disp->makeFrame($mw);

	my $rh_entryvalue = ();
	my $label1 = $disp->addLabel($frame, 'Question');
	my $rh_entryprop_qu = {text=>'<question>', width=>90, align=>'center', anchor=>'n'};
	$rh_entryvalue->{question} = $disp->addEntry($frame, $rh_entryprop_qu);
	
	my $label2 = $disp->addLabel($frame, 'Left tag');
	my $rh_entryprop_lt = {text=>'<left label>', width=>20, align=>'left', anchor=>'w'};
	$rh_entryvalue->{lefttag} = $disp->addEntry($frame, $rh_entryprop_lt);

	my $label3 = $disp->addLabel($frame, 'Right tag');
	my $rh_entryprop_rt = {text=>'<right label>', width=>20, align=>'right', anchor=>'w'};
	$rh_entryvalue->{righttag} = $disp->addEntry($frame, $rh_entryprop_rt);

	$label1->grid(-row=>1, -column=>1, -sticky=>'e');
	$rh_entryvalue->{question}->{widget}->grid(-row=>1, -column=>2, -columnspan=>3);
	
	$label2->grid(-row=>2, -column=>1, -sticky=>'e');
	$rh_entryvalue->{lefttag}->{widget}->grid(-row=>2, -column=>2);

	$label3->grid(-row=>2, -column=>3, -sticky=>'e');
	$rh_entryvalue->{righttag}->{widget}->grid(-row=>2, -column=>4);

	return $rh_entryvalue;
}

sub setUpButtons{
	my $frame = $disp->makeFrame($mw);
#	my $capture = $frame->Button (
#		-text => "Take Picture",
#		-command => \&snapshot,
#		-anchor =>'w',
#	)->pack();

#	my $remove = $frame->Button (
#		-text => "Remove last image",
#		-command => \&removeLastImage,
#	)->pack();

#	my $combine = $frame->Button (
#		-text => "Complete image",
#		-command => \&completeImage,
#		-anchor => 'e'
#	)->pack();
	my $rh_buttons = {};
	$rh_buttons->{cont} = $frame->Button(
			-text => "Start recording (go from left to right)",
			-command => \&continuousSwitch,
			-anchor => 'e'
	)->pack();
	return $rh_buttons;
	
	

}

sub removeLastImage{
	my $rm = pop(@imageset);
#	$rm->delete;
}

sub removeAllImages{

#	my $size = @imageset;
#	for (my $i=0; $i<$size; $i++){
#		$imageset[$i]->delete;
#	}
	@imageset = ();
}

sub completeImage{
	#Make up a comp image filename.
	&compileImg;
	&removeAllImages;
}

sub compileImg{
        my $fname = "full" . (sprintf("%04d",$i)) . ".jpg";
        while (-f $fname) {
                $fname = "full" . (sprintf("%04d",++$i)) . ".jpg";
        }

	my $img = &tileImageStrips;
	my $jpg_data = $img->jpeg;
        open (COMP,">" . "nolabels_$fname") || die;
        print COMP $jpg_data;
        close COMP;

	my $imgAxis = &addAxis($img);
	$jpg_data = $imgAxis->jpeg;
        open (COMP,">" . "$fname") || die;
        print COMP $jpg_data;
        close COMP;
}

sub continuousSwitch{
	if ($continuous->{switch} == 0){
		&removeAllImages;
		$continuous->{switch} = 1;
		$rh_buttons->{cont}->configure(-text => "Stop recording"),
	}else{
		&completeImage;
		$continuous->{switch} = 0;
		$rh_buttons->{cont}->configure(-text => "Start recording (go from left to right)"),
	}
	print "Cont switch = " . $continuous->{switch} . "\n";
}

sub tileImage{
	my @gdimage = ();
	my $size = @imageset;
	for (my $i=0; $i < $size; $i++){
	#	my $gd = GD::Image->new($lastFrame) || die;
		my $gd = $imageset[$i];
		push (@gdimage, $gd);
	}
	my $tiles = GD::Tiler->tile(
                Images => \@gdimage,#\@imageset,
                Background => 'lgray',
        	Format => 'jpeg', 
 	        ImagesPerRow=>$size,
		Center => 1,
                ) || die;

	my $img = GD::Image->new($tiles);
	return $img;
}

sub tileImageStrips{
	my $size = @imageset;
	my @strip = ();
	for (my $i=0; $i<$size; $i++){
		my $imgstrip = &makeIntoStrip($imageset[$i]);
		push (@strip, $imgstrip);
	}
	my $tiles = GD::Tiler->tile(
                Images => \@strip,#\@imageset,
                Background => 'lgray',
        	Format => 'jpeg', 
 	        ImagesPerRow=>$size,
		Center => 1,
                ) || die;

	my $img = GD::Image->new($tiles);
	@strip = ();
	return $img;
}

sub addAxis{
	my $img = shift;
	my ($width, $height) = $img->getBounds();
	my $tabs = int($width / 100) + 3;
	my $bg = $img->colorAllocate(127,126,127);
	my $black = $img->colorExact(1,1,1);
	my $white = $img->colorAllocate(255,255,255); 
	my $font = "/usr/share/fonts/truetype/ubuntu-font-family/UbuntuMono-R.ttf";
	#add question
	my $qy = 20;
	my $qtxt = ${$rh_entryvalue->{question}->{rs_value}};
	my $qlength = length($qtxt);
	my $qx =  ($width/2) - $qlength*7;	
	my $rh_qrect = {img=>$img,x=>$qx,y=>$qy,length=>$qlength,color=>$white};	
	&makeTextShade($rh_qrect);	
	$img->stringFT($black,$font,22,0,$qx,$qy,$qtxt);

	#add left label
	my $ly = $height - 25;
	my $ltxt = ${$rh_entryvalue->{lefttag}->{rs_value}};
	my $llength = length($ltxt);
	my $lx = 15;
	my $rh_lrect = {img=>$img,x=>$lx,y=>$ly,length=>$llength,color=>$white};	

	&makeTextShade($rh_lrect);	
	$img->stringFT($black,$font,20,0,$lx,$ly,$ltxt);

	#add left label
	my $ry = $height - 25;
	my $rtxt = ${$rh_entryvalue->{righttag}->{rs_value}};
	my $rlength = length($rtxt);
	my $rx = $width - 15 - ($rlength*14);	
	my $rh_rrect = {img=>$img,x=>$rx,y=>$ry,length=>$rlength,color=>$white};	
	&makeTextShade($rh_rrect);	
	$img->stringFT($black,$font,20,0,$rx,$ry,$rtxt);

	my $rh_AxisLine = {img=>$img,
			   x=>$lx+($llength*15),
			   y=>$ly,
			   width=>$rx - ($lx+$llength*15), 
			   tabs =>$tabs, 
			   color=>$white};	
	&makeAxisLine($rh_AxisLine);

	return $img;
}

sub makeTextShade{
	my ($rh_arg) = @_;
	$rh_arg->{img}->filledRectangle($rh_arg->{x}-5,
				$rh_arg->{y}-27,
				$rh_arg->{x}+($rh_arg->{length}*15),
				$rh_arg->{y}+5,
				$rh_arg->{color});
}

sub makeAxisLine{
	my ($rh_arg) = @_;
	$rh_arg->{img}->filledRectangle($rh_arg->{x}-5,
				$rh_arg->{y}-27,
				$rh_arg->{x}+($rh_arg->{width}),
				$rh_arg->{y}-22,
				$rh_arg->{color});
	
	my $increment = $rh_arg->{width} / $rh_arg->{tabs};
	for (my $i=$increment; $i < $rh_arg->{width}; $i += $increment){
		$rh_arg->{img}->filledRectangle($rh_arg->{x} + $i,
					$rh_arg->{y}-22,
					$rh_arg->{x}+ $i + 5,
					$rh_arg->{y}-5,
					$rh_arg->{color});
	}
}

#sub printFullImage{
#	my $rh_arg = shift;
#        my $cardNo = shift;
#        my $image = GD::Image->newFromJpeg($rh_arg->{imgfile});
#        my $black = $image->colorAllocate(0,0,0);
#	my $height = 140;
#	my $txt = $rh_arg->{question};
#	my $font = "/usr/share/fonts/truetype/ubuntu-font-family/UbuntuMono-R.ttf";
#	$image->stringFT($black,$font,20,0,20,$height,$txt);
#        my $jpg_data = $image->jpeg;
#       open (FLE,">wthquestion_" . $rh_arg->{imgfile} . ".jpg") || die;
#        print FLE $jpg_data;
#        close FLE;
#}

