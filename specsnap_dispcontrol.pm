
package specsnap_dispcontrol{
	use strict;
	use warnings;
	use Tk;
	use stg_disp;
	use open qw/:std :utf8/;

	sub new{
		my $mess = shift;
		my $this = {};
		bless $this, $mess;
		return $this;
	}

	sub makeWindow{
		my (	
			$this, 
			$title
		   ) = @_; 
		my $win = MainWindow->new(-title=>$title);
		$win->geometry(($win->maxsize())[0] .'x'.($win->maxsize())[1]);
		return $win;
	}
	
	sub makeFrame{
		my (
			$this,
			$win
		   ) = @_;
		my $frm = $win->Frame(-bg => stg_disp::CNVSTYLE->{'bg'},
					   -relief => 'sunken',
				     	   -width => 400,
				           -height => 100)->pack(-expand => 1, -fill => 'both');
		return $frm;
	}

	sub addHeader{
		my (
			$this,
			$frm,
			$title
		   ) = @_;
		my $header = $frm -> Label(-text=>$title,
			     -font=>stg_disp::HEADERSTYLE->{'font'}, 
#		      	     -bg=>stg_disp::CNVSTYLE->{'bg'}
			      )	-> pack();
		return $header;
	}

	sub addLabel{	
		my (
			$this,
			$frm,
			$text
		   ) = @_;
		my $txtBlk = $frm -> Label(
#			  	-width=>100,
			  	-text=>$text,
		      		-bg=>stg_disp::CNVSTYLE->{bg},
			        -wraplength=>stg_disp::TEXTSTYLE->{wraplength},
			        -justify=>stg_disp::TEXTSTYLE->{align},
			        -font=>stg_disp::TEXTSTYLE->{font}
		    		)-> pack();
		return $txtBlk;
	}
	
	sub addEntry{
		my(
		   $this,
		   $frm,
		   $rh_entrypoint,
		  ) = @_;
		my @var = @_;
		my $value = $rh_entrypoint->{text};	
		my $entry = $frm->Entry(
					-textvariable=>\$value,
					-background=>stg_disp::ENTRYSTYLE->{bg},
					-width=>$rh_entrypoint->{width},
					-justify=>$rh_entrypoint->{align},
					-font=>stg_disp::ENTRYSTYLE->{font},
			#		-anchor=>$rh_entrypoint->{anchor}
					)->pack();
#		$entry->bind('<FocusOut>'=>  sub{$this->updateDBfromWigPoint($rh_entrypoint, $value)});                                                              
#		$entry->bind('<Destroy>'=>  sub{print "bang!\n"; $this->updateDBfromWigPoint($rh_entrypoint, $value)});
		my $rh_return = {widget=>$entry, rs_value=>\$value};                                                              
		return $rh_return;
	}

	sub addText{
		my(
		   $this,
		   $frm,
		   $rh_textpoint,
		  ) = @_;
		my @var = @_;
		my $value = $rh_textpoint->{value};	
		my $t = $frm->Scrolled('Text', -setgrid=> 'true', -height=> 3, -scrollbars=>'e');
		$t->pack(qw/-expand no -fill both/);
		$t->insert('0.0', $value);
		$t->mark(qw/set insert 0.0/);

	#	$t->bind('<FocusOut>'=>  sub{$this->updateDBfromWigPoint($rh_textpoint, $value)});                                                              
	#	$t->bind('<Destroy>'=>  sub{print "bang!\n"; $this->updateDBfromWigPoint($rh_textpoint, $value)});                                                              
		return $t;
	}

	sub simpleTest{
		my ($this, $r_entryref, $animal) = @_;
		print "I have been run successfully and have received an $animal for " . $r_entryref->{field} . "\n";
	}

}
1;
