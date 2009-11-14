#!/usr/bin/perl

#---------------------------------------------------------------------------------    
#
#	This script is licensed under GPL version 3
#
#----------------------Script proper----------------------------------------------


  # need to fool the noweb "notangle" utility, switch markup modes etc.
  $lt = "<";
  $gt = ">";
  $lt_esc = "&lt;";
  $gt_esc = "&gt;";
  $dash = "-";
  $dot = "\.";

  # ----- GENERAL settings -----
  
  # am I a module? 1:0
  $i_am_module = 1;

  # print toc? 1:0
  $print_toc = 1 unless defined $print_toc;
    
  # keep TOC expanded on initial load? "block":"none"
  $toc_expanded = $toc_expanded || "block";

  # keep TOC expanded in initial load? "block":"none"
  $ind_expanded = $ind_expanded || "none";
  # what is the file extention to weave it? (perms must allow execution!)
  # e.g. "scriptname.weave" or "scriptname.cgi" etc.
  $weave_extension = $weave_extension || "weave";	# default is "weave"

    # what is the file extention to tangle it? (perms must allow execution!)
    # e.g. "scriptname.tangle",  "scriptname.pl" etc.
    $tangle_extension = $tangle_extension || "tangle";	# default is "tangle"


    #When tangling, should I use the built-in tangler? 0:1
    # (if 0, the "pass-through" tangling will call "notangle"
    # from Ramsey's "noweb" tools, must be installed and in your path)
    # use_builtin_tangler = 0; # default for now is to use external "notangle"
    $use_builtin_tangler = $use_builtin_tangler || 0; 

    # Actually, let's always do it and disallow unsetting
    # number lines ? 1 : else
    $line_numbering = 1;

    # how are doc sections marked? "dotHTML":"rawHTML"
    $weave_markup = $weave_markup || "rawHTML"; # default is "rawHTML"

    if ($weave_markup eq "dotHTML") {
	$tag_open_symbol = $dot;	# this will take care of default
	$tag_close_symbol = $dot;	# when no var is set in the Lit Src file
    }
    elsif ($weave_markup eq "rawHTML") { 
	$tag_open_symbol = $lt;
	$tag_close_symbol = $gt;
    } #fi


    # enable MathML interpretation? 1 : 0
    $enable_ASCIIMathML = $enable_ASCIIMathML || 0;
    # If enabled, set the path; default is local in current dir
    $path_to_ASCIIMathML = $path_to_ASCIIMathML || "ASCIIMathML_with_modified_escapes.js";

  # -- MAIN DESPATCHER ----

  # check if $i_am_module and set filenames to $0 - or 
  # process CL options otherwise

  # (temp) - 2 options, to weave and to tangle in module mode:
  #
  if ( $0 =~ m!\w+\.$weave_extension$! ) { goto WEAVE_ME }
  elsif ( $0 =~ m!\w+\.$tangle_extension$! )  {goto TANGLE_ME}
  else {
  print <<end_of_print;

	USAGE:
	Not set to tangle (wrong file extension).
	Set config variables at the top of the script.  

end_of_print
  }

TANGLE_ME:

    open LITSOURCE, "<$0";

  if ( $use_builtin_tangler ) {



    my $chunk_beg_pattern = q(^<\<(.*)>\>=);
    my $chunk_end_pattern = q(^@\s.*$);
    my $chunk_ref_pattern = q(<\<(.*?)>\>[^=]); # can be used several times in a line

    my $current_chunk_name = "";
	my $current_chunk_start_foff = ""; # "foff" is a "file offset"
	my %file_offsets_hash = ();
    
    my $line_num = 0;
	my $previous_line_foff = 0; # "foff" is a "file offset"


 while (<LITSOURCE>) {
    $line_num++;

	# --- CODE CHUNKS -- not inside documentation section
    if ( m!$chunk_beg_pattern! .. m!$chunk_end_pattern! ) {


        if ( $_ =~ m!$chunk_beg_pattern! ) {
	    $current_chunk_name = $1;
	    $current_chunk_start_foff = tell LITSOURCE;

	    push @{$file_offsets_hash{$current_chunk_name}}, $current_chunk_start_foff;
	    #~ print "[***debug: I am chunk $1 -- I start at $current_chunk_start_foff***]\n";

        }


        elsif ( $_ =~ m!$chunk_end_pattern! )  {

	    $current_chunk_end_foff = $previous_line_foff;
	    push @{$file_offsets_hash{$current_chunk_name}}, $current_chunk_end_foff;
	    #~ print "[+++debug: $current_chunk_name ends at off $current_chunk_end_foff++++]\n\n";

		$current_chunk_name = "";
            }



	elsif ( $_ =~ m!$chunk_ref_pattern!g ) {

	# simplest case: one match on its own line
		# DEBUG printouts:
		#~ $match_position_in_line = pos($_);
		#~ print "\t**chunk ref $1 at pos $match_position_in_line in line**\n";

	# mark the foffs of the chunk so far
	$current_chunk_ref_foff = $previous_line_foff;
	push @{$file_offsets_hash{$current_chunk_name}}, $current_chunk_ref_foff;
	
	#~ print "\t..while in the file I am at offset $current_chunk_ref_foff..\n"; 
	# push special strings "ref" and "this chunk name" into the main hash.
	# That's how we'll know to call another chunk recursively.
	
	push @{$file_offsets_hash{$current_chunk_name}}, "ref";
	push @{$file_offsets_hash{$current_chunk_name}}, $1;

	#.. and push the offset again, to serve as a start of the next chunk splinter. 
	push @{$file_offsets_hash{$current_chunk_name}}, (tell LITSOURCE);

	} # fisle
	


        else { # chunk body

	    ; # nop; here just not to hide an implicit case
	    #~ print "."; # debug: show dots for lines 
            }



    } #fi

	$previous_line_foff = tell LITSOURCE;

  } #eliwh




 sub print_chunk {
	    my $chunk_being_printed = pop @_;
	    #~ print "\n---- printing chunk $chunk_being_printed --------\n";
	
	# iterate over splinters of a chunk, which are foff pairs
	while (@{$file_offsets_hash{$chunk_being_printed}}) {


    my $snippet_position = shift @{$file_offsets_hash{$chunk_being_printed}};
    my $snippet_end = shift @{$file_offsets_hash{$chunk_being_printed}};

	#~ print "DEBUG GOT: beg $snippet_position -- end $snippet_end\n";

	if ($snippet_position eq "ref") {
	
	#~ print "got a ref $snippet_position here\n";
	print_chunk($snippet_end);
	
	}
	else { # .. print it here
    seek LITSOURCE, $snippet_position,  0;
    read LITSOURCE, $buffer_out, ($snippet_end - $snippet_position);
    print $buffer_out;
	}


	 } # elihw
	
	 return 1;
	} # bus -- ends the recursive sub



	#~ $root_chunk = "chunk 1";
	#~ $root_chunk = "DEBUG print one reference";
	$root_chunk = "*";

	print_chunk($root_chunk); 


  } 
  else { # pass to "notangle" from "noweb" tools by Ramsey

    open TANGLE_PIPE, "| notangle -t4 -";

    while  (<LITSOURCE>) {

	    if ( m!^<\<(.*)>\>=! ... m!^@\s*$! ) { # -- CODE CHUNKS ONLY -- 
		print TANGLE_PIPE $_;
	    }

    } # elihw

    close TANGLE_PIPE;

  } #; esle, pass-through clause end

    close LITSOURCE;
 exit;



WEAVE_ME:

#1. Set formatting strings for weaver

  #----SETTING FORMATTING STRINGS-----------
  
$html_head = <<head_end_1;  

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" /> 

head_end_1

#switch on ASCIIMathML.js library if enabled in template options:
if ($enable_ASCIIMathML) {
$html_head .= "\n" . qq(<script type="text/javascript" src="$path_to_ASCIIMathML"></script>) . "\n";
    }

$html_head .= <<head_end;


<script language="javascript">

function toggleDiv(divid) {
var el = document.getElementById(divid);
el.style.display = (el.style.display == 'block') ? 'none' : 'block';
}


function toggleCombined(divid){
    if(document.getElementById(divid).style.display == 'none'){
      document.getElementById(divid).style.display = 'block';
	document.getElementById("toc"+divid).className="hilited";
    }
    else{
      document.getElementById(divid).style.display = 'none';
	document.getElementById("toc"+divid).className="unhilited";
    }
}


function showAll(){
for(i=1; i <= 10000; i++){
    document.getElementById(i).style.display = 'block';
    document.getElementById("toc"+i).className="hilited";
    };
}

function hideAll(){
for(i=1; i <= 10000; i++){
    document.getElementById(i).style.display = 'none';
    document.getElementById("toc"+i).className="unhilited";
    };
}

</script>
<style type="text/css" media="screen">


BODY {
	FONT-SIZE: 10pt;
	<!--FONT-FAMILY: sans-serif -->
	background: #f0f0f0;
	}
FIELDSET {
	BORDER-RIGHT: #000000 1px solid; 
	BORDER-TOP: #000000 1px solid; 
	BORDER-LEFT: #000000 1px solid; 
	BORDER-BOTTOM: #000000 1px solid; 
	PADDING-RIGHT: 5px; 
	PADDING-LEFT: 5px; 
	PADDING-BOTTOM: 2px; 
	PADDING-TOP: 5px;
	MARGIN-BOTTOM: 1px; 
	background: #f5f5f5; 
	color: #000000;
	}
LEGEND {
	BORDER-RIGHT: #a9a9a9 1px solid; 
	BORDER-BOTTOM: #a9a9a9 1px solid;
	BORDER-TOP: #a9a9a9 1px solid; 
	BORDER-LEFT: #a9a9a9 1px solid; 
	PADDING-RIGHT: 20px; 
	PADDING-LEFT: 20px; 
	PADDING-BOTTOM: 5px; 
	PADDING-TOP: 5px; 
	FONT-WEIGHT: bold;  
	BACKGROUND: #fdfdfd; 
	color: #000000;
	}
PRE	{
        PADDING-LEFT: 20px; 
        PADDING-RIGHT: 5px; 
        padding-top: 0px; 
        padding-bottom: 6px;
        MARGIN-BOTTOM: 1px; 
        BORDER-TOP: #a9a9a9 0px solid;
        BORDER-RIGHT: #a9a9a9 0px solid; 
        BORDER-LEFT: #a9a9a9 0px solid;
        BORDER-BOTTOM: #a9a9a9 0px solid;        
	background: #fefefe;
	}


.tocfieldset {
	background: #ffffff; 
	color: #000000;
	}

.codefieldset {
	BORDER-RIGHT: #000 1px solid; 
	BORDER-TOP: #000 1px solid; 
	BORDER-LEFT: #000 1px solid; 
	BORDER-BOTTOM: #000 1px solid; 
	background: #ffffff; 
	color: #000;
	MARGIN-BOTTOM: 1px; 
	PADDING-LEFT: 15px; 
	PADDING-RIGHT: 5px; 
	PADDING-BOTTOM: 10px; 
	PADDING-TOP: 1px;
	}
.codelegend {
	BORDER-RIGHT: #777 1px solid; 
	BORDER-TOP: #777 1px solid; 
	BORDER-LEFT: #777 1px solid; 
	BORDER-BOTTOM: #777 1px solid
	PADDING-RIGHT: 10px; 
	PADDING-LEFT: 10px; 
	PADDING-TOP: 2px; 
	PADDING-BOTTOM: 2px; 
	background: #ffffff; 
	color: #00b;
	FONT-WEIGHT: bold;  
	/font-variant: small-caps;
	/font-style: italic;
	}



.chunkref {
        color: #00b;	
        background: #f6f6f6;
        /font-style: italic;
        font-weight: bold;
        /font-variant: small-caps;
	}


.outertable {
	width: 99%; 
	cellpadding: 25; 
	background: #ffffff; 
	border: 1px solid;
	}

.hl	{
	 ;
        PADDING-LEFT: 5px; PADDING-RIGHT: 5px; 
        padding-top: 5px; padding-bottom: 5px;
        MARGIN-BOTTOM: 1px; 
        BORDER-TOP: #a9a9a9 0px solid;
        BORDER-RIGHT: #a9a9a9 0px solid; 
        BORDER-LEFT: #a9a9a9 0px solid;
        BORDER-BOTTOM: #a9a9a9 0px solid;        
        background: #f5f5f5;	
        width: 70%;
	}

.hl-wide {
	 ;
        PADDING-LEFT: 5px; 
        PADDING-RIGHT: 5px; 
        padding-top: 15px; 
        padding-bottom: 15px;
        MARGIN-BOTTOM: 1px; 
        BORDER-TOP: #a9a9a9 0px solid;
        BORDER-RIGHT: #a9a9a9 0px solid; 
        BORDER-LEFT: #a9a9a9 0px solid;
        BORDER-BOTTOM: #a9a9a9 0px solid;        
        background: #fbfbfb;	
	}

.lnum {

	color: #a0a0a0;
	/background: #fbfbfb;
	}

.unhilited {background-color:white}
.hilited {background-color:#c0c0ff}


</STYLE>

</head>
head_end

$html_body_table = "<center><table class='outertable'><tr><td>";
$html_body_table_end = "\n</td></tr></table></center></body></html>\n";


	

$folding_section_start1_str = <<'fold_sect_start_1_xxx';
	<fieldset><legend><a href="javascript:;" onmousedown="toggleCombined('$section_num');">
fold_sect_start_1_xxx


$folding_section_start2_str = <<'fold_sect_start_2_xxx';
</a></legend></fieldset>
<p>
<div id="$section_num" style="display:$fold_state"> $highlight_state  
<ul>

fold_sect_start_2_xxx


$folding_section_end_str = <<'folding_section_end_xxx';
</ul>
<p>
<br>
<i><font size=-1>
<a href="javascript:;"onmousedown="toggleCombined('$section_num_prev');">
Close the subsection</a></font>
</i> -- <i><font size=-1>
<a href="javascript:;" onmousedown="showAll();">
expand all</a> -- 
<a href="javascript:;" onmousedown="hideAll();">
collapse all</a>
</font></i>

<p>
</div>

folding_section_end_xxx


$code_frameset_start_pre = "<pre><fieldset class='codefieldset'><legend class='codelegend'>";
$code_frameset_start_post = "=</legend>";
$code_frameset_end = "</fieldset></pre>\n";





#2. accumulate result in a buffer
#2. accumulate result in a buffer


# vars for the main loop over lines of the target file

 $chunkbuf = ''; # collects whole formatted project file in memory
 $tocbuf = "";	# will accumulate TOC contents, i.e. small
 @indbuf = ();  # accumulates index of code chunks, small
 #%indbuf = ();
 @headings = ();	# the stack for nested subsections numbers/ids

 $section_num = 0;
 $section_num_prev = 0;
 $section_level = 0;
 $prev_section_level = $section_level;
 $line_counter = 0;
 $in_pre_tag = 0;

open FF, "< $0";


while (<FF>) {

   $line_counter++;

    # cut out the MOLLY.pl invocation itself, the top of the Lit src file
    #if ( m%^#-+\s*?start of script% ... m%^xxxxxxxxxxxx% ) {  
    if ( m%^__DATA__% ... m%^xxxxxxxxxxxx% ) {
    s!^__DATA__\s*$!!;




	if ( m!^(goto)?<\<(.*)>\>=! ... m!^@\s*$! ) { # -- CODE CHUNKS -- 
		$chunk_title = $2;

		s/&/&amp;/g;	# escape &
		s/</&lt;/g;	# escape <
		s/>/&gt;/g;	# escape >

		if (m!(&lt;&lt;(.+?)&gt;&gt);(=)?!) 
		  {
		  $reference = $1;
		  $ind_str = "&lt;&lt;$2&gt;&gt; $section_num";
		  if (defined $3) {$ind_str .= "<sub>def</sub>"}
		  else { s!$reference!<font class='chunkref'>$reference</font>! }

		  unshift @indbuf, $ind_str;

		} # fi - chunks index accumulation

		# simple fieldset frames around code snippets
		s!^(goto)?&lt;&lt;(.+)&gt;&gt;=!$code_frameset_start_pre$1&lt;&lt;$2&gt;&gt;$code_frameset_start_post!;
		s!^@\s*$!$code_frameset_end!;

		if ( $line_numbering ) { 
		$chunkbuf .= "<font class='lnum'>" . $line_counter . "</font>   " . $_;
		}
		else{
		$chunkbuf .= $_;
		}

	} # fi code chunks

	# -- SECTION HEADINGS 
   #elsif ( m!\.(\+)?h(\d)\.(.*?)\./h\d\.! ) {	# old version, no "rawHTML" enabled yet
   elsif ( m!$tag_open_symbol(\+)?h(\d{1,2})$tag_close_symbol(.*?)$tag_open_symbol/h\d{1,2}$tag_close_symbol! ) {	



	# -- using split vars for substitution to avoid
	#	regexps and need to keep old state --	

	$section_num_prev = $section_num;
	$section_num = $section_num + 1;


		#default for fold state in "settings" ??
		if ($1 eq "+") {
		    $fold_state="block";
		    $highlight_state = qq!  <script language=javascript> 
		    document.getElementById("toc"+ $section_num).className='hilited';
		    </script> !;
		} 
		else {
		    $fold_state="none";
		    $highlight_state = "";
		};
		$section_level = $2;
		$section_title = $3;


	

	

	$folding_section_start1 = $folding_section_start1_str;
	$folding_section_start2 = $folding_section_start2_str;
	$folding_section_end = $folding_section_end_str;


	$folding_section_start1 =~ s!(\$section_num)!$1!ee;
	$folding_section_start2 =~ s!(\$section_num)!$1!ee;
	$folding_section_start2 =~ s!(\$fold_state)!$1!ee;
	$folding_section_start2 =~ s!(\$highlight_state)!$1!ee;
	$folding_section_end =~ s!(\$section_num_prev)!$1!ee;


	$section_id = $section_level . '-' . $section_num;


	# finish previous subsection if not the first section in the file
	# ..and deal with nesting of sections according to their "depth level"

	# this is NOT the first section:
	if ( exists $headings[0] ){

		($prev_section_level, $prev_section_num)  = split /-/, $headings[0];

		if ($section_level == $prev_section_level){

		# close prev, start new
		$chunkbuf .= $folding_section_end;
		shift @headings;
		
		}

		elsif($section_level < $prev_section_level){
		
		  # close a bunch of them, in a loop -- THEN start a new one.
		  do  {
			($prev_section_level, $section_num_prev) = split /-/, shift @headings;
			
			$folding_section_end = $folding_section_end_str;
			$folding_section_end =~ s!(\$section_num_prev)!$1!ee;
			$chunkbuf .= $folding_section_end;

		   } while ( $section_level < $prev_section_level );
		}
	} # fi not the first section


	# common operations		
	unshift @headings, $section_id ;
	$chunkbuf .= $folding_section_start1;
	$chunkbuf .= "<font class='lnum'><i>(" . $section_num . ")</i></font>" . "&nbsp;" . $section_title .
	    "</a>&nbsp;<a><font class='lnum' size=-1><sub><i>(line " .
	    $line_counter . ")</i></sub></font>"; 
	$chunkbuf .= $folding_section_start2;

	#$chunkbuf .= "\n" . "<font class='lnum'><i>------ line " . $line_counter . 
	#	    " ------</i></font><br>\n";


	$toc_indent = "&nbsp;" x ($section_level * 7);
	#$toc_indent = "&nbsp;" x (($section_level-1) * 7 );
	#$tocbuf .= "\n<p>\n" if ( $section_level == 1 ); 
	$tocbuf .= $toc_indent . 
		"<i>" . $section_num . "</i>" .
		qq/&nbsp;<a href="javascript:;" onmousedown="toggleCombined(/ .  
		$section_num . 
		qq/);" id="toc/ . $section_num .
		qq/"><b>/ .
		$section_title . "</a>&nbsp;<a><font class='lnum' size=-1><i>(line " .
		    $line_counter . ")</i></font>" .
		    "</b></a><br>\n";

   } #; fisle: end elif headings

	


	elsif( $weave_markup eq "dotHTML" ) {	# dotHTML formatter here

	      s/^=begin.*$//;	# - eliminate perl escaping, start
	      s/^=cut.*$//;		# - eliminate perl escaping, end
   	      #s/^{{{\d+(.*)$/$1/;	# - eliminate vim folding markup, start 
					# - dummy, as it is killed in "headings" processing 
	      s/^}}}\d+//;	# - eliminate vim folding markup, end

		s/&/&amp;/g;	# escape &
		s/</&lt;/g;	# escape <
		s/>/&gt;/g;	# escape >


	      # Paragraphs and line breaks are automatic now:
	      # ... unless we are dealing with the "preformat" tag
		#--note! that ranges do not work here
		$in_pre_tag = 1 if (m!\.pre\.!);
		$in_pre_tag = 0 if (m!\./pre\.!);;

		s/\.(\/?)pre\./<$1pre>/g;

	    unless ($in_pre_tag) {
	    (m/^\s*$/) and s/$_/<p>\n/
	    or s/\n/<br>\n/;
	    }
	      # originally I separated header from the body with such a line
	      #s/^#-----.*/starting the table here/;
	      s/^#-----.*//;


		# add more here

		s/\.(\/?)b\./<$1b>/g;
		s/\.(\/?)i\./<$1i>/g;
		s/\.(\/?)ul\./<$1ul>/g;
		s/\.(\/?)li\./<$1li>/g;
		s/\.(\/?)ol\./<$1ol>/g;
		s/\.(\/?)s\./<$1s>/g;
		s/\.(\/?)div\./<$1div>/g;
		s/\.br\./<br>/g;
		s/\.p\./<p>/g;
		s/\.sp\./&nbsp;/g;

		s/\.(\/?)tab\./<$1ul>/g;	# "tabbing" with "ul"


		# this is some bullshit ???
		s/\.hr\./<hr /g;
		s/\.\/hr\./>/g;

		s!\.a\.(.+?)\.\/a\.!<a href=$1>$1</a>!g;

		# rudimentary &nbsp; s p a c i n g &nbsp (one word only)
		#s!\.x\.(.+?)\./x\.!join " ","&nbsp;&nbsp;",(split //, $1),"&nbsp;&nbsp;"!eg;

		# slightly better spacing (phrases, too):
		# although redundant  with more work than is needed
		if ( m!(\.x\.)(.+?)(\./x\.)!g) {
		    s!(\.x\.)(.+?)(\./x\.)!join " _ ", $1, (split / /, $2), $3!eg;
		    s!\.x\.(.+?)\./x\.!join " ", (split //, $1)!eg;
		    s!  _  ! &nbsp; !g;
		}


		# generic for all tags with options
		s!\.&lt;\. !<!g;
		s! \.&gt;\.!>!g;


		$chunkbuf .= $_;

	}
	elsif( $weave_markup eq "rawHTML" ) {	# if the doc chunks marked up with real HTML
		s!^#-----.*!!;

	      #s/^{{{\d+(.*)$/$1/;	# - eliminate vim folding markup, start 
					# - dummy, as it's killed in "headings" processing 
	      s/^}}}\d+//;	# - eliminate vim folding markup, end


	      # Paragraphs and line breaks are automatic now:
	      # ... unless we are dealing with the "preformat" tag
		#--note! that ranges do not work here
		$in_pre_tag = 1 if (m!<pre>!);
		$in_pre_tag = 0 if (m!</pre>!);;


		unless ($in_pre_tag) {
		(m/^\s*$/) and s/$_/<p>\n/
		or s/\n/<br>\n/;
		}


		$chunkbuf .= $_;
	} # esle -- for rest of the body





	# debug
	#print "---- $_";

   } # fi "start of script"

} #elihw over the whole input file

	


 foreach (@headings)  {

	($section_level, $section_num_prev) = split /-/, $_;
	$folding_section_end = $folding_section_end_str;
	$folding_section_end =~ s!(\$section_num_prev)!$1!ee;
	$chunkbuf .= $folding_section_end; 

	};


#3. print out the TOC, the Chunks Index, the output buffer and close the page.

  # begin the page:
  #print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">', "\n";
  print "<html>\n  $html_head\n <body>  $html_body_table \n";

  # print out the TOC, the Chunks Index, the output buffer and close the page.


print <<end_of_print;
<p><fieldset class='tocfieldset'><legend><b>TABLE OF CONTENTS: outline of the document structure</b></legend>

<ul>
<p>
<br>
<div class='hl' align=center>
<a href="javascript:;" onmousedown="toggleDiv('tochowto');">
<b>HOW TO USE THE FOLDING DOCUMENT [expand/collapse]</b></a>
</div>
<div id='tochowto' style='display:none' style='background:#ffffff'> 
<p>
<ul>
<li><b>Collapsing is necessary when</b> you work on some code and must exclude 
<br>irrelevant sections of the rest of the literate project file. This 
<br>greatly helps to clear thinking by eliminating a general feeling of 
<br>being in a maze of code and unnecessary "housekeeping" tasks.
<br>One can say that there is a limited "buffer capacity" in the human
<br>mind, and relieving it of the need to remember where things are in a 
<br>larger file, at which other points one must fill in values or adjust
<br>invocation etc. <i>immediately makes the user "more intelligent"</i>
</li><li><b>To toggle</b> a section open/closed, click on the corresponding link
<br>Remember to open <i>all sections above it</i> for it to become visible.
</li><li><b>To restore the default view</b> reload the page in the browser.
</li><li>
<b>To keep some sections open</b> upon each reload - 
<br>e.g. you work on the code, update it constantly and cannot reopen it 
<br>again and again - mark their sections in the source file with a plus, 
<br>i.e. write the opening tag (only)  as +h2, +h3 (in &lt; &gt;  or in dots
<br>for dotHTML). Again, all sections above must be marked open too. 
<p><b>Note that</b> "expand all" and "collapse all" disregard these settings.
<br>Reload the page after using those options to again view the text according 
<br>to your preferences.
</li><li>
<b> To use the Index </b>, click on the numbered sections in the TOC above
<br>(opening them; use highlighting as a guide; when sections are visible,
<br>the slider on your browser window  will shorten too), or "expand all", 
<br>and then use your browser's Find function to highlight all chunk name 
<br>instances in the visible text
</li><li>
<b>To search for variables etc.</b>, "expand all" text - or manually 
<br>expand needed sections - and then use your browser's Find function to 
<br>highlight all and jump between the found items.
<p></li>

</div> 
<p>
<br>
<p>
<div class='hl' align=center>
<!--i><font size=-3> expand all -- collapse all</font></i-->
<a href="javascript:;" onmousedown="toggleDiv('tocmain');">
<b>TABLE OF CONTENTS [expand/collapse]</b></a>
</div>

<div id='tocmain' style='display:$toc_expanded' style='background:#ffffff'> 
<p>
<br>
<p>
end_of_print


 print "$tocbuf" if $print_toc;
 #print "$tocbuf";

print "</div>\n";


print <<end_of_print;
<p>
<br>
<p>
<!--fieldset><legend-->
<div class='hl' align=center>
<a href="javascript:;" onmousedown="toggleDiv('indbuf');">
<b>INDEX of Code Chunks [expand/collapse]</b></a>
</div>
<!--/legend></fieldset-->
<p>
<div id='indbuf' style='display:$ind_expanded' style='background:#ffffff'> 
<ul>
<p>
<b>"Def" subscript</b> means the chunk is defined, while a bare number means 
<br>the chunk is being used in the given section.
<p>
end_of_print


	 $ind_outbuf = '';
	 $prev_ch_name = '';

	 #for (sort @indbuf){ print $_, "<br>";}

	 for (sort @indbuf){

	   ($ch_name, $closing_bracket, $ref_num) = split /&gt;/, $_; 
		#/ - for editor colouring bug

	    if ( $ch_name eq $prev_ch_name ){ 
	      $ind_outbuf .= " <b>" . $ref_num . "</b> ";
	    }
	    else{
	      print  $ind_outbuf, "<br>\n"; 
	      $ch_namestr = $ch_name;
	      $ch_namestr =~ s!&lt;&lt;!!;
	      $ind_outbuf = 
	      	"<b>&lt;&lt;</b><font class='chunkref'>" . 
	      	$ch_namestr . 
	      	"</font><b>&gt;&gt;</b> -- <b>" . 
	      	$ref_num . 
	      	"</b> ";
	    }
	    $prev_ch_name = $ch_name;

	 }; # rof - forming the code chunks index

	print $ind_outbuf, "<br>\n";


  # The "expand all" "collapse all" control

print <<end_of_print;
</div>\n<p>
<br>
<p><div class='hl' align=center><i>
<a href="javascript:;" onmousedown="showAll();">
expand all</a> -- 
<a href="javascript:;" onmousedown="hideAll();">
collapse all</a>
</i></div><p>
end_of_print


 print "</ul></fieldset><p>\n<br>";


# The FULL OUTPUT, the file body:
 	print $chunkbuf;


# close the page
	print $html_body_table_end;
	
exit;

#--- END OF SCRIPT ---


# END OF SCRIPT
