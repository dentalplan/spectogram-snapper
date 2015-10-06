package stg_disp;
require Exporter;
use strict;
use warnings;
use open qw/:std :utf8/;


my @ISA     = qw(Exporter);
my @EXPORT =  qw (	
			SCREEN_RES
			HEADERSTYLE
			TEXTSTYLE 
			ENTRYSTYLE
			BTTNSTYLE
			CNVSTYLE
		);

	use constant SCREEN_RES => 1440;
	use constant HEADERSTYLE => {font=>'Ubuntu 26',  align=>'center'};
	use constant TEXTSTYLE => {font=>'Ubuntu 12', align=>'left', wraplength=>750};
	use constant ENTRYSTYLE => {font=>'Ubuntu 9', align=>'left', wraplength=>700, bg=>'white'};
	use constant BTTNSTYLE =>  {font=>'Ubuntu 12', width=>50, relief=>'solid', bg=>'white', bd=>2};
	use constant CNVSTYLE => {bg=>'white'};

