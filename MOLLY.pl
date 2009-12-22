#!/usr/bin/perl

#-----------------------------------------------------------------------------------------
# MOLLY - A MO-DULE FOR LI-TERATE PROGRAMMING
#-----------------------------------------------------------------------------------------
# ............................................
# .......licensed under GPL version 3.........
# ............................................
# ....... Author: unixtechie; email: .........
# .. /same/ ..  at .. yahoo .. dot .. com ....
# ............................................
# ..... Git depos. - docs and download: ......
# http://github.com/unixtechie/Literate-Molly/
# ............................................
#
#-----------------------------------------------------------------------------------------
#---|-4-|-8-|-12----|-20------|-30------|-40------|-50------|-60------|-70------|-80------|


  # need to fool the noweb "notangle" utility, switch markup modes etc.
  $lt = "<";
  $gt = ">";
  $lt_esc = "&lt;";
  $gt_esc = "&gt;";
  $dash = "-";
  $dot = "\.";

  # ----- GENERAL settings -----
  
        # print toc? 1:0
        $print_toc = 1 unless defined $print_toc;
        
        # keep TOC expanded on initial load? "block":"none"
        $toc_expanded = $toc_expanded || "block";
        
        # keep TOC expanded in initial load? "block":"none"
        $ind_expanded = $ind_expanded || "none";

        # what is the file extention to weave it? (perms must allow execution!)
        # e.g. "scriptname.weave" or "scriptname.cgi" etc.
        $weave_extension = $weave_extension || "weave"; # default is "weave"

        # what is the file extention to tangle it? (perms must allow execution!)
        # e.g. "scriptname.tangle",  "scriptname.pl" etc.
        $tangle_extension = $tangle_extension || "tangle";      # default is "tangle"
        
        
        #When tangling, should I use the built-in tangler? 0:1
        # (if 0, the "pass-through" tangling will call "notangle"
        # from Ramsey's "noweb" tools, must be installed and in your path)
        # use_builtin_tangler = 0; # default for now is to use external "notangle"
        $use_builtin_tangler = $use_builtin_tangler || 0; 
        
        # Actually, let's always do it and disallow unsetting
        # number lines ? 1 : else
        $line_numbering = 1;

        # Print LitSource's line nums as a reference in the tangled output? deflt is 0.
        $print_ref_linenos_when_tangling = $print_ref_linenos_when_tangling || 0; 
        $code_sections_comment_symbol = $code_sections_comment_symbol || "# ";


        # find and print root chunks in the LitSrc (i.e. instead of tangling when it is run
        # as "./LitSrc.tangle" from command line) ? 0:1
        $show_all_roots = $show_all_roots || 0; # default is not (i.e. to tangle)


        # how are doc sections marked? "dotHTML":"rawHTML"
        $weave_markup = $weave_markup || "rawHTML"; # default is "rawHTML"
        
        if ($weave_markup eq "dotHTML") {
        $tag_open = $dot;        # this will take care of default
        $tag_close = $dot;       # when no var is set in the Lit Src file
        }
        elsif ($weave_markup eq "rawHTML") { 
        $tag_open = $lt;
        $tag_close = $gt;
        } #fi


        # enable MathML interpretation? 1 : 0
        $enable_ASCIIMathML = $enable_ASCIIMathML || 0;
        # If enabled, set the path; default is local in current dir
        $path_to_ASCIIMathML = $path_to_ASCIIMathML || "ASCIIMathML_with_modified_escapes.js";

  # -- MAIN DESPATCHER WITH CL----
  use Getopt::Std;


sub usage {

    print STDERR<<'end_of_usage';

    USAGE: MOLLY.pl [options] [--] filename

        -h, or no filename
                get this help message


        TANGLING Options:
                Tangling mode is default, no special option to force needed.

        -R "root_chunk_name", 
                tangle starting from this chunk. if omitted, "*" is default.

        -l 'comment symbol for your language',
                add comments with coresponding line numbers in Lit Src

        -i  information on root chunks


        WEAVING options:

        -w,  
            weave from the external target file (rawHTML), or
        -wd 
            same for dotHTML-encoded files

        -m 'URL or path/to/ASCIIMathML.js library'
            process the file with ASCIIMathML lib. Option used in addition
            to mode-setting -w or -wd


        FORESTRY mode:

        -t -1, or -t 3 etc. (for default rawHTML-encoded files)
        -dt -2, or -dt 1 etc. (for "dotHTML"-encoded files)
            run as a "tree replant" filter: 
            move subtree up 1 level or down 3 levels, etc. 
            when employed as a filter on an editor's selected text.
            Renumbers html headings and vim folding marks.

        MOLLY.pl [-d] -t# < LitSource.file 
            renumber headings and vim folding marks for a whole file from CL



    FOR INTERNALLY MOLLIFIED FILES:
        shortcut invocation - depending on file extension. If run as script

        "lit_prog_file.tangle" 
                tangles to STDOUT, from default root "*" only. 
        "lit_prog_file.weave" 
                weaves to STDOUT as folding HTML; usable under CGI
        
        / OR: set your own extensions in your lit.source configuraton section /

end_of_usage

 exit;
}


my @LITSOURCE_list = ();
my %LITSOURCE_hash = ();

  # -1- shortcut invocations for "mollified" LitSrc file depending on its extension ---

  if ( $0 =~ m!\w+\.$weave_extension$! ) { 

        open LITSOURCE, "< $0" or die "\n\tcould not open the target file\n\n";
        goto WEAVE_ME;
    }
    elsif ( $0 =~ m!\w+\.$tangle_extension$! )  {

        open LITSOURCE0, "< $0" or die "\n\tcould not open the target file for tangling\n\n";
        push @LITSOURCE_list, 'LITSOURCE0';
        $LITSOURCE_hash{'LITSOURCE0'} = $0;
        goto TANGLE_ME;
  }

  # -2- MOLLY.pl as a standalone script is called from CGI, nothing in here yet ---

  elsif (defined $ENV{'REQUEST_METHOD'}) {


    print "Content-Type: text/html; charset=utf-8\n\n";
        print <<_XXX_;
        <html><body>
        <p>
        <b>I was caled as CGI, but this invocation seems to be meaningless.</b><br>
        Maybe you meant to "weave", but set a wrong file extension.<br>
        Goodbye.<br>
        <i>-- MOLLY.pl --</i>
        <p>
        </body></html>
_XXX_

  exit;


  }

  # -3- several cases for application of Molly to an external target file from CL --- 

  #elsif (-t STDIN) { 
  else { # do not check; assume it is command line now; will take piped input now.

    
        #print STDERR "$0 was called from command line..\n";
    
        #-- getopts invocation
            getopts("hwm:dt:l:R:i", \%cl_args);
    
        # -- set doc sections markup (if not default=html): 
            if($cl_args{d}) { 
                $tag_open = $dot;
                $tag_close = $dot;
                $weave_markup = "dotHTML";
                #print STDERR setting dotHTML markup\n";
            }
    
        # -- "forestry"  mode - act as a filter to move subtree levels
            if($cl_args{t}) { 
                $replant_tree = $cl_args{t};
                #print STDERR "moving subtree by '$replant_tree' levels\n";
                goto FORESTRY;
            }
    
    
        # -- print USAGE if not evoked correctly
            if( (! defined $ARGV[0] ) or  ( $cl_args{h} ) ) { usage(); exit };
    
        # -- does target file exist?
            if ( -f $ARGV[0] ) {
                ; # nop, a debug printout
                #print STDERR "target file to operate on is $ARGV[0]\n";
            }
            else { 
                die "\n\tERROR: No target file $ARGV[0] seem to exist\n\n";
            };
    
    
        # -- Final CL despatch, do it: --
            
    
            if($cl_args{w}) { # this is weaving - and I put "forestry" in here too 
    
                if (@ARGV > 1) {
                print STDERR "\n\n\tDo not know how to weave several files\n";
                print STDERR "\tweaving the first one: $cl_args{w}\n\n"; 
                }
    
                if ($cl_args{m}) {
                    # print STDERR "using ASCIIMathML.js - located at $cl_args{m}\n";
                    $enable_ASCIIMathML = 1;
                    $path_to_ASCIIMathML = $cl_args{m};
                }
    
                open LITSOURCE, "< $ARGV[0]" || die "could not open the target file\n";
                goto WEAVE_ME;
    
            }
    
            else { # this is tangling, default action, no opt
    
                
                if($cl_args{d}) { 
                    #print STDERR "doc sections in coments; comment char is $cl_args{d}\n";
                    };
            
                if($cl_args{u}) { 
                    #print STDERR "applying UN-tangling with script char is $cl_args{u}\n";
                    };
            
                if($cl_args{i}) { 
                    #print STDERR "printing information on roots, discovered chunks\n";
                    $show_all_roots = 1;
                    
                    };
            
                if($cl_args{l}) { 
                    #print STDERR "will add reflines; comment char is $cl_args{l}\n";
                    $print_ref_linenos_when_tangling = 1;
                    $code_sections_comment_symbol = $cl_args{l};
                    };
            
                # -- getting the root chunk for tangling --
                if($cl_args{R}) { 
                    $root_chunk = $cl_args{R};
                    print STDERR "tangling root chunk '$root_chunk'\n";
                    };
            
    
                for (my $countem=0; $countem < @ARGV; $countem++) {
    
                 $LITSOURCE_multi = 'LITSOURCE' . $countem;
                 open $LITSOURCE_multi, "< $ARGV[$countem]"
                     or die "\n\tCould not open target file $ARGV[$countem]\n\n";
    
                 push @LITSOURCE_list, $LITSOURCE_multi;
                 $LITSOURCE_hash{$LITSOURCE_multi} = $ARGV[$countem];
    
                } # rof
    
                goto SEEK_PEEK_TANGLER;
    
            } # fi - CL final despatch
    
        exit; #redundant and unused
    

    }

#  # -4- other cases ---
#
#  else {
#
#        die "MOLLY.pl: I do not know how I was called, exiting anyway\n";
#
#  } # esle, fi - end of despatcher

exit;  # just in case  


TANGLE_ME:


  if ( $use_builtin_tangler ) {

    
    SEEK_PEEK_TANGLER:
    
    

    my $chunk_beg_pattern = q(^<\<(.*)>\>=);
    my $chunk_end_pattern = q(^@\s.*$);
    my $chunk_ref_pattern = q(<\<(.*?)>\>[^=]); # can be used several times in a line
    
    my $current_chunk_name = "";
    my $current_chunk_start_foff = 0;; # "foff" is a "file offset"
    my $current_chunk_end_foff = 0;

    my %file_offsets_hash = ();
    my %file_lines_hash = ();
    my $parents_list = ();

    my $line_num = 0;
    my $previous_line_foff = 0; # "foff" is a "file offset"


foreach $LITSOURCE_multi(@LITSOURCE_list) {


 while (<$LITSOURCE_multi>) {
    $line_num++;

    # --- CODE CHUNKS -- not inside documentation section
    if ( m!$chunk_beg_pattern! .. m!$chunk_end_pattern! ) {

    
        if ( $_ =~ m!$chunk_beg_pattern! ) {
            $current_chunk_name = $1;
            $current_chunk_start_foff = $LITSOURCE_multi . "-" . (tell $LITSOURCE_multi);
    
            # -- collecting offset and line number, actually
            push @{$file_offsets_hash{$current_chunk_name}}, $current_chunk_start_foff;
            push @{$file_lines_hash{$current_chunk_name}}, $LITSOURCE_multi . "-" . $.;
            #~ print "----> chunk $1 line $. offset $current_chunk_start_foff\n";
    
        }
    
    
        elsif ( $_ =~ m!$chunk_end_pattern! )  {
    
            $current_chunk_end_foff = $LITSOURCE_multi . "-" . $previous_line_foff;
            # -- collecting offset and line number:
            push @{$file_offsets_hash{$current_chunk_name}}, $current_chunk_end_foff;
            push @{$file_lines_hash{$current_chunk_name}}, $LITSOURCE_multi . "-" . $.;
            #~ print "\tline $. offset $current_chunk_end_foff<------\n";
    
            $current_chunk_name = "";
        }
    
    
 elsif ( $_ =~ m!$chunk_ref_pattern!g ) {

    my $line = $_;
    my $current_foff_pos =  $previous_line_foff;
    my $initial_margin = "";
    my $homegrown_pos = 0;

    while ($line =~ m!(.*?)<\<(.*?)>\>!g) {

        my $pre_ref_match = $1;
        my $ref_match = $2;
        my $len_pre_ref_match = length $pre_ref_match;
        my $len_ref_match = length $ref_match;

        # "end" of prev pair; collecting offset and line number
        push @{$file_offsets_hash{$current_chunk_name}}, 
            $LITSOURCE_multi . "-" . ($current_foff_pos + $len_pre_ref_match); 
        push @{$file_lines_hash{$current_chunk_name}}, $LITSOURCE_multi . "-" . $.;


        #-------deal with pushing ("ref", "chunkname") pair -----
        # special id string for refs
        push @{$file_offsets_hash{$current_chunk_name}}, "ref";
        # name of reference
        push @{$file_offsets_hash{$current_chunk_name}}, $ref_match; 
        # .. and form pairs for toposort (cycles check, search roots):
        push @parents_list, ($current_chunk_name, $ref_match);

        # -- next a special entry for refs: (left_margin)
        # I keep tabs and spaces and subst all else to spaces
        $pre_ref_match =~ s!\S! !g;
        $initial_margin .= $pre_ref_match;
        push @{$file_offsets_hash{$current_chunk_name}}, $initial_margin; 
        $initial_margin .= " " x ( $len_ref_match + 2*( length "<>") );      

        my $homegrown_pos = $len_pre_ref_match + $len_ref_match + 2*(length "<>");
        my $end_of_match_pos = $current_foff_pos + $homegrown_pos;

        # "start" a new pair.. - ok, let's not use "pos" at all, if it fails
        # .. and collect both offset and the line number
        push @{$file_offsets_hash{$current_chunk_name}}, 
            $LITSOURCE_multi . "-" . $end_of_match_pos;
        push @{$file_lines_hash{$current_chunk_name}}, $LITSOURCE_multi . "-" . $.;

        #  I'll need to reset current_foff_pos to the pos
        #   (or to the directly caclucalted offset, if I prefer that):
        $current_foff_pos = $end_of_match_pos; 

    } # elihw

    # This is where chunk refs get an extra newline ?

 } # fisle

    
    else { # chunk body
        ; # nop; here just not to hide an implicit case
        #~ print "."; # debug: show dots for lines 
    }
    

    } #fi

    $previous_line_foff = tell $LITSOURCE_multi;

  } # eliwh

} # hcaerof iteration over all files collecting file offsets


    

sub topological_sort {

    my $flag_show_roots = shift;
    my %pairs;  # all pairs ($l, $r)
    my %npred;  # number of predecessors
    my %succ;   # list of successors
    my $opt_b = 0;

    my @topo_list_out = '';

    while ( @_ ) {
        my $l = shift @_;
        my $r = shift @_;
        my @l = ($l, $r);
        #my ($l, $r) = my @l = split;
        next unless @l == 2;
        next if defined $pairs{$l}{$r};
        $pairs{$l}{$r}++;
        $npred {$l} += 0;
        ++$npred{$r};
        push @{$succ{$l}}, $r;
    }

    # create a list of nodes without predecessors
    my @list = grep {!$npred{$_}} keys %npred;

    #--print discovered roots, if asked--
    if ($flag_show_roots) {
    print "\n\t--roots of multi-chunk chains--\n";
    for (@list) { print "\t$lt$lt$_$gt$gt\n";}
    print "\t-------------------------------\n";
    }

    while (@list) {
        $_ = pop @list;
        unshift @topo_list_out, $_;
        #print "$_\n";
        foreach my $child (@{$succ{$_}}) {
            if ($opt_b) {       # breadth-first
                unshift @list, $child unless --$npred{$child};
            } else {    # depth-first (default)
                push @list, $child unless --$npred{$child};
            }

        }
    }

    # mm.. better if I warn, print out the list so far, and then exit
    #   the user will have the place where the problem occured 
    #~ warn "cycle detected\n" if grep {$npred{$_}} keys %npred;
    if ( grep {$npred{$_}} keys %npred ){
        warn  "\n\tERROR: cycle detected - aborting execution!\n"; 
        print "\n---chunks discovered before the 'cycle' ERROR - sorted topologically ---\n";
        for (@topo_list_out) {
            print "$_\n";
        } # rof

    exit;
    } # fi check for cycles

    # -DEBUG-
    #    if ($flag_show_roots){
    #    print "\t--all chunks discovered--\n";
    #    for (@topo_list_out) {
    #        print $_, "\n";
    #    }
    #    exit;
    #    }

return @topo_list_out;
#return 1;
} # tros_lacigolopot


# will abort if cycles detected. Does not detect all cycles? - need to check
my @chunks_in_chains = topological_sort($show_all_roots, @parents_list);

if ($show_all_roots){

    # non-standalone roots are already printed from inside "topological_sort"
    print "\n\t------single-chunk roots-------\n";
    my %lookup_hash = ();
    for (@chunks_in_chains){ $lookup_hash{$_} = 1;}

    for (keys %file_offsets_hash) { 
        print "\t$lt$lt$_$gt$gt\n"
            unless exists $lookup_hash{$_};
        }
    print "\t-------------------------------\n\n";
exit;
}

            
        # USAGE: print_chunk(name_of_chunk, left_margin, print_newline_flag)
        sub print_chunk {
        
         (my $chunk_being_printed,
            my $snippet_left_margin, 
                  my $snippet_print_newline_flag, @rest) = @_; 
        
        
         #~ print "\n---- printing chunk $chunk_being_printed --------\n";
         #~ print "DEBUG: got left.m. $snippet_left_margin nl. flag $snippet_print_newline_flag \n";
        
         # -- error mess. not to fail silently --
         unless ( defined $file_offsets_hash{$chunk_being_printed} ) {
            die "\n\tERROR: chunk $chunk_being_printed not found in file $ARGV[0]\n\n";
         }
        
        
         # iterate over splinters of a chunk, which are foff pairs
         my $iterate_lines = 0;
         for ( my $iterate_foffs = 0;
                    exists $file_offsets_hash{$chunk_being_printed}[$iterate_foffs];)
         {
        
            my $snippet_position =  $file_offsets_hash{$chunk_being_printed}[$iterate_foffs++];
            my $snippet_end = $file_offsets_hash{$chunk_being_printed}[$iterate_foffs++];
        
            #~ print "debug got: beg $snippet_position -- end $snippet_end\n";
        
            
        if ($snippet_position eq "ref") {
    
            my $snippet_left_margin_ref = 
                $file_offsets_hash{$chunk_being_printed}[$iterate_foffs++];
    
            # any call to a ref uncurs "print newline" flag of 0
            print_chunk($snippet_end, $snippet_left_margin_ref, 0);
        
        }
            
        else { # .. print it here
    
            (my $litsrc_fhname_beg, my $litsrc_line_beg) =
                split '-', $file_lines_hash{$chunk_being_printed}[$iterate_lines++];
            (my $litsrc_fhname_end, my $litsrc_line_end) =
                split '-', $file_lines_hash{$chunk_being_printed}[$iterate_lines++];
    
            (my $litsrc_fhname_beg, my $litsrc_foff_beg) = split '-', $snippet_position;
            (my $litsrc_fhname_end, my $litsrc_foff_end) = split '-', $snippet_end;
            # DEBUG prints:
            #print "in file_beg $litsrc_fhname_beg $litsrc_foff_beg\n";
            #print "in file_end $litsrc_fhname_end $litsrc_foff_end\n------\n"; 
    
    
            # the file is always the same, though. You cannot have one chunk splinter
            # start in one file and end in another one. (2 splinters can live in 2 files)
            seek $litsrc_fhname_beg, $litsrc_foff_beg,  0;
            read $litsrc_fhname_end, $buffer_out, ($litsrc_foff_end - $litsrc_foff_beg);
    
            #----Newlines at the end of chunks and refs. 
            # only for the last splinter of a chunk, do newline control:
            if ( ((scalar @{$file_offsets_hash{$chunk_being_printed}}) - $iterate_foffs ) == 0 )
            { 
                    # works, but is suspicious logically:
                    # maybe I just have not invented a counterexample yet, and
                    # it's a trap waiting for its quarry. But it works
                    $buffer_out =~ s!\n([\s]*)$!$1! unless ($snippet_print_newline_flag);
            }
    
            #----Left indent/margin. Seems OK
    
            $chunk_left_margin =  $snippet_left_margin;
            $buffer_out =~ s!(\n)!$1$chunk_left_margin!sg;
    
    
            #----And Print Out:
    
            if ($print_ref_linenos_when_tangling){
            print $code_sections_comment_symbol, 
                "[line ", $litsrc_line_beg," in file ",
                $LITSOURCE_hash{$litsrc_fhname_beg}, "]__start" ;
            print "_________________________________\n";
            }
            
            print $buffer_out;
    
            if ($print_ref_linenos_when_tangling) {
            print $code_sections_comment_symbol,
                "[line ", $litsrc_line_end," in file ",
                $LITSOURCE_hash{$litsrc_fhname_end}, "]__end" ;
            print "___________________________________\n";
            }
    
        } #esle for printout
    
        
         } # rof non-destructive
                
             return 1;
        } # bus -- ends the recursive sub
        
    
        $root_chunk = $root_chunk || "*";

# USAGE: print_chunk(name_of_chunk, left_margin, print_newline_flag)
        print_chunk($root_chunk, "", 1); 

        # and close all the opened files
        for (@LITSOURCE_list){close $_;}

    
    exit;
    

  } 
  else { # pass to "notangle" from "noweb" tools by Ramsey

    open TANGLE_PIPE, "| notangle -t4 -";

    while  (<LITSOURCE0>) {

            if ( m!^<\<(.*)>\>=! ... m!^@\s*$! ) { # -- CODE CHUNKS ONLY -- 
                print TANGLE_PIPE $_;
            }

    } # elihw

    close TANGLE_PIPE;
    close LITSOURCE0;

  } #; esle, pass-through clause end

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
    $html_head .= "\n"
    . qq(<script type="text/javascript" src="$path_to_ASCIIMathML"></script>)
    . "\n";
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


function open_all_above(someid){

    elem = document.getElementById(someid);
        elem.style.display = 'block';
        document.getElementById('toc'+someid).className = 'hilited';
        
    while (elem.parentNode.id != 1) {
        if (elem.parentNode.nodeType == 1) {
        elem.parentNode.style.display = 'block';
        //document.getElementById(elem.parentNode.id).className = 'hilited';
        var toc_elem = document.getElementById('toc'+elem.id);
        if (toc_elem) {toc_elem.className = 'hilited'};
        }
        elem = elem.parentNode;
    }
}



// DELETING a CLONE -- this works too:
function DeleteVirtualNode(someid) {
    
    elem = document.getElementById(someid);

    while (elem.childNodes.length > 0) {
    elem.removeChild(elem.firstChild);
    }  
}

// CREATING a CLONE - this works
/* for clean execution - run "delete" before any creation */
function CreateVirtualNode(clone_from_id, append_to_id){
        DeleteVirtualNode(append_to_id);

    if ( document.getElementById(append_to_id).childNodes.length == 0 ) {
    var elem = document.createElement("div");

    elem = document.getElementById(clone_from_id).cloneNode(1);
    elem.style.display = 'block';
    document.getElementById(append_to_id).appendChild(elem); 

    } /* fi - do not create duplicates of the cloned node */ 
    
}


</script>

<style type="text/css" media="screen">


BODY {
        FONT-SIZE: 10pt;
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
PRE     {
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
        }
.chunkref {
        color: #00b;    
        background: #f6f6f6;
        font-weight: bold;
        }
.outertable {
        width: 99%; 
        cellpadding: 25; 
        background: #ffffff; 
        border: 1px solid;
        }
.hl     {
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
.hl-white     {
        PADDING-LEFT: 5px; PADDING-RIGHT: 5px; 
        padding-top: 5px; padding-bottom: 5px;
        MARGIN-BOTTOM: 1px; 
        BORDER-TOP: #a9a9a9 0px solid;
        BORDER-RIGHT: #a9a9a9 0px solid; 
        BORDER-LEFT: #a9a9a9 0px solid;
        BORDER-BOTTOM: #a9a9a9 0px solid;        
        background: #fff;    
        width: 70%;
        }
.hl-wide {
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
        }
.unhilited {background-color:white}
.hilited {background-color:#c0c0ff}
.linked_chunk {
        PADDING-RIGHT: 5px; 
        PADDING-LEFT: 5px; 
        PADDING-BOTTOM: 5px; 
        PADDING-TOP: 5px; 
        BORDER-TOP: #c0c0c0 1px solid;
        BORDER-RIGHT: #c0c0c0 1px solid; 
        BORDER-LEFT: #c0c0c0 1px solid;
        BORDER-BOTTOM: #c0c0c0 1px solid;              
        color: #505050;
        background: #ffffff;
        }
.linked_chunk_legend {
        PADDING-RIGHT: 5px; 
        PADDING-LEFT: 5px; 
        PADDING-BOTTOM: 3px; 
        PADDING-TOP: 3px; 
        BORDER-TOP: #c0c0c0 1px solid;
        BORDER-RIGHT: #c0c0c0 1px solid; 
        BORDER-LEFT: #c0c0c0 1px solid;
        BORDER-BOTTOM: #c0c0c0 1px solid;              
        color: #505050;
        background: #ffffff;
        }
a:visited { color: blue; }

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


$code_fieldset_start_pre = q(<pre><fieldset class='codefieldset'><legend class='codelegend'>);
$code_fieldset_start_post = "=</legend>";
$code_fieldset_end = "</fieldset></pre>\n";


#2. accumulate result in a buffer
#2. accumulate result in a buffer


# vars for the main loop over lines of the target file

 $chunkbuf = ''; # collects whole formatted project file in memory
 $tocbuf = "";  # will accumulate TOC contents, i.e. small
 @indbuf = ();  # accumulates index of code chunks, small
 @headings = ();  # the stack for nested subsections numbers/ids
 %headings_id_hash = ();
 %chunks_id_hash = ();

 $section_num = 0;
 $section_num_prev = 0;
 $section_level = 0;
 $prev_section_level = $section_level;
 $line_counter = 0;
 $in_pre_tag = 0;



while (<LITSOURCE>) {

$line_counter++;


if ( ($line_counter == 1) && (m!^#.*perl!) ) {

    # Matched? - this must be either the mollifying template or some perl script.
    
    do {
        $_ = <LITSOURCE>;
        $line_counter++;
        if (eof LITSOURCE) {
            print "\n\t--------ERROR: wrong target file format for weaving--------\n";
            print "\tmay be a regular perl script, without a call for Molly\n\n";
            exit;
        }
    } until ( lc($_) =~ m!^do.*molly!) ;    
    
    # throw away lines until DATA, then process/weave normally
    do {
        $_ = <LITSOURCE>;
        $line_counter++;
        if (eof LITSOURCE) {
            print "\n\t--------ERROR: wrong target file format for weaving--------\n";
            print "\tdid not find the  __DATA__ keyword  in first pos on its line\n\n";
            exit;
        }
    } until ( m!^__DATA__! ) ;

    next;

} # fi cutting out MOLLY.pl template/config  if present in lit.source target file



if ( m!^<\<(.*)>\>=! ... m!^@\s*$! ) { # -- CODE CHUNKS -- 

        s/&/&amp;/g;    # escape &
        s/</&lt;/g;     # escape <
        s/>/&gt;/g;     # escape >
        my $codechunk_id = "";

      if ( m!(&lt;&lt;(.+?)&gt;&gt;)(=)?! ) 
          {
          $chunk_title = $2;
          $reference = $1;
          $ind_str = "&lt;&lt;$2&gt;&gt; $section_num";
          if (defined $3) {$ind_str .= "<sup>def</sup>"}
          else { s!$reference!<font class='chunkref'>$reference</font>! }

          unshift @indbuf, $ind_str;

        # /.. "if" is not finished in this chunk yet.. read on/

            # cut-in for virtual links handling: create codechunk_id 
            if (defined $3) {
            
                $codechunk_id = 'codechunk' . $.;
                push @{$chunks_id_hash{$chunk_title}}, $codechunk_id; # with splinters

                my $splinter_number = '';
                $splinter_number = @{$chunks_id_hash{$chunk_title}}
                    if @{$chunks_id_hash{$chunk_title}} > 1;

                # simple fieldset frames around code snippets if chunk definition
                # /changing current line $_ which will get appended to $chunkbuf/
                s!^&lt;&lt;(.+)&gt;&gt;=!
                <div id=$codechunk_id>
    $code_fieldset_start_pre&lt;&lt;$1&gt;&gt<sub>$splinter_number</sub>$code_fieldset_start_post!x;

            } # fi - cut-in for virtual chunk links

        } # fi - chunks index accumulation


        # close fieldset frame at end of code chunk
        s!^@\s*$!$code_fieldset_end</div>!;


        if ( $line_numbering ) { 
        $chunkbuf .= "<font class='lnum'>" . $line_counter . "</font>   " . $_;
        }
        else{
        $chunkbuf .= $_;
        }

} # fi code chunks


# -- SECTION HEADINGS 
#elsif ( m!\.(\+)?h(\d)\.(.*?)\./h\d\.! ) {     # old version, no "rawHTML" enabled yet
elsif
  ( m!$tag_open(\+)?h(\d{1,2})$tag_close(.*?)$tag_open/h\d{1,2}$tag_close! )
  {  

        # -- using split vars for substitution to avoid
        #       regexps and need to keep old state --   

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

        # add-on for virtual nodes; DEBUG for now
        $stripped_section_title = $section_title;
        $stripped_section_title =~ s!\s*(.*\S)\s*!$1!;
        $headings_id_hash{$stripped_section_title} = $section_num;


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

        # end of "finish previous subsection if not the first section in the file"

        # common operations             
        unshift @headings, $section_id ;
        $chunkbuf .= $folding_section_start1;
        $chunkbuf .= "<font class='lnum'><i>(" . $section_num . ")</i></font>"
            . "&nbsp;" . $section_title
            . "</a>&nbsp;<font class='lnum' size=-1><sub><i>(line "
            . $line_counter
            . ")</i></sub></font>"; 

        $chunkbuf .= " <font size=-2><i><a href='#tocancor'>toc</a></i></font>";

        #for F-links
        $chunkbuf .= "<a name='" . $section_num . "'>"; 

        $chunkbuf .= $folding_section_start2;

        #$chunkbuf .= "\n" . "<font class='lnum'><i>------ line " . $line_counter . 
        #           " ------</i></font><br>\n";

        # TOC Navigation: open all parents, then junp to section
        my $open_all_and_jump =  
                q/&nbsp;<a href="#/
                . $section_num
                . q/" onmousedown="open_all_above(/  
                . $section_num . 
                q/);" >/ . '))</a>';


        # TOC Navigation: open_all_above(someid)
        $tocbuf .= 
                $open_all_and_jump . "&nbsp;" 
                . q/&nbsp;<a href="javascript:;" onmousedown="open_all_above(/  
                . $section_num . 
                q/);" >/ . '<i>' . $section_num . '</i></a>';

        $toc_indent = "&nbsp;"x4 . ".&nbsp;" x (($section_level-1) * 3);

        # old-disabled
        #$toc_indent = "&nbsp;" x ($section_level * 7);
        #$toc_indent = "&nbsp;" x (($section_level-1) * 7 );
        #$tocbuf .= "\n<p>\n" if ( $section_level == 1 ); 

        $tocbuf .= $toc_indent . 
                #--disabled--#"<i>" . $section_num . "</i>" .
                qq/&nbsp;<a href="javascript:;" onmousedown="toggleCombined(/ .  
                $section_num . 
                qq/);" id="toc/ . $section_num .
                qq/"><b>/ .
                $section_title . "</a>&nbsp;<a><font class='lnum' size=-1><i>(line " .
                    $line_counter . ")</i></font>" .
                    "</b></a>";

        # and end the line
        $tocbuf .= "<br>\n";



} #; fisle: end elif headings        



else { # this is the body of the doc section

        if( $weave_markup eq "rawHTML" ) {      # if the doc chunks marked up with real HTML
                s!^#-----.*!!;

              #s/^{{{\d+(.*)$/$1/;      # - eliminate vim folding markup, start 
                                        # - dummy, as it's killed in "headings" processing 
              s/^}}}\d+//;      # - eliminate vim folding markup, end


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

        } # fi - default rawHTML formatter for body of doc chunks



        elsif( $weave_markup eq "dotHTML" ) {   # dotHTML formatter here

              s/^=begin.*$//;   # - eliminate perl escaping, start
              s/^=cut.*$//;             # - eliminate perl escaping, end
              #s/^{{{\d+(.*)$/$1/;      # - eliminate vim folding markup, start 
                                        # - dummy, as it is killed in "headings" processing 
              s/^}}}\d+//;      # - eliminate vim folding markup, end

                s/&/&amp;/g;    # escape &
                s/</&lt;/g;     # escape <
                s/>/&gt;/g;     # escape >


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

                s/\.(\/?)tab\./<$1ul>/g;        # "tabbing" with "ul"


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

        } # fisle - end of "dotHTML" body formatter
        


    if (m!^\s*\[\[LINKED_CHUNK(_\d+)?\s+(.*\S)\s*\]\]\s*<br>$!) { # -- CHUNK LINKS --
        my $index_str = "&lt;&lt;$2&gt;&gt; " . $section_num . "<sup>link</sup>";
        unshift @indbuf, $index_str;
    }

} # esle, fi -- end of processing inside 'while' over the file lines.


    # debug
    #print "---- $_";


} #elihw over the whole input file

close LITSOURCE;

 foreach (@headings)  {

        ($section_level, $section_num_prev) = split /-/, $_;
        $folding_section_end = $folding_section_end_str;
        $folding_section_end =~ s!(\$section_num_prev)!$1!ee;
        $chunkbuf .= $folding_section_end; 

        };


#3. print out the TOC, the Chunks Index, the output buffer and close the page.

# begin the page:

  # /disabled doctype line/ - it garbles output of TOC (!!)
  #print q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" 
  #                 "http://www.w3.org/TR/html4/loose.dtd">), "\n";

  print "<html>\n  $html_head\n <body>  $html_body_table \n";

# print out the TOC, the Chunks Index, the output buffer and close the page.


print <<end_of_print;
<p><fieldset class='tocfieldset'>
<legend><b>TABLE OF CONTENTS: outline of the document structure</b></legend>

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
<li><b>Collapsing is necessary when</b> you work on code and must exclude 
<br>irrelevant sections of the rest of the literate project file. This 
<br>greatly helps to clear thinking by eliminating a general feeling of 
<br>being in a maze of code and unnecessary "housekeeping" tasks.
<br>One can say that there is a limited "buffer capacity" in the human
<br>mind, and relieving it of the need to remember where things are in a 
<br>larger file, at which other points one must fill in values or adjust
<br>invocation etc. <i>immediately makes the user "more intelligent"</i>
<p>
</li><li><b>TOC: to toggle</b> a section open/closed, click on the <i>corresponding link</i>
<br>Remember to open <i>all sections above it</i> for it to become visible.
</li><li><b>TOC: to open all sections above</b> some internal subsection to make
<br>it visible, click on the <i>section number</i> in the column on the left.
</li><li><b>TOC: to open all above and jump</b> click on the leftmost symbol.
<p>
</li><li><b>To restore the default view</b> <i>reload</i> the page in the browser.
<p>
</li><li>
<b>To keep some sections open</b> upon each reload: supposing you
<br>work on the code, constantly update it and cannot bother to reopen it 
<br>again and again - mark the headings for the sections in the source file
<br>with a plus, i.e. write the opening tag (only)  as +h2, +h3. Again, all
<br>sections above must be marked open too. 
<br><b>Note that</b> "expand all" and "collapse all" disregard these settings.
<br>Reload the page after using those options to again view the text
<br>according to your preferences.
<p>
</li><li>
<b> To use the Index </b>, click on the numbered sections in the TOC above
<br>(opening them; use highlighting as a guide; when sections are visible,
<br>the slider on your browser window  will shorten too), or "expand all", 
<br>and then use your browser's Find function to highlight all chunk name 
<br>instances in the visible text
<p>
</li><li>
<b>To search for variables etc.</b>, "expand all" text - or manually 
<br>expand needed sections - and then use your browser's Find function to 
<br>highlight all and jump between the found items.
<p></li></ul>

</div> 
<p>
<br>
<p>
<div class='hl' align=center>
<p>
<a href="javascript:;" onmousedown="toggleDiv('tocmain');">
<b>TABLE OF CONTENTS [expand/collapse]</b></a>
<a name="tocancor"></a>
</div>

<div id='tocmain' style='display:$toc_expanded' style='background:#ffffff'> 

<div class='hl-white' align=center>
<font size=-1 color=darkgrey><i>
<p><b>Section name</b> toggles expanded state. <b>Subsection number</b> on the left opens
<br>all parent sections to make it visible. <b>Leftmost symbol</b> opens parents and
<br>jumps to the section.
</i></font>
</div>

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
A <b>"def" superscript</b> means the chunk is defined,<br>
a <b>"link"</b> that the chunk is being linked to from that section,<br>
and a <b>bare number</b> means the chunk is being used in a section.
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


#The FULL OUTPUT, the file body (with links handling  added):


sub print_chunk_link {

(my $name_of_linked_chunk, $virtual_id, my $created_clone_div_id, my $shown_splinter_num) = @_;

print <<"end_of_clone_sect";

    <fieldset class='linked_chunk'>
    <legend class='linked_chunk_legend'>
    $lt_esc$lt_esc$name_of_linked_chunk$gt_esc$gt_esc $shown_splinter_num
    <font size=-2><i>
    <a href="javascript:;"
    onmousedown="CreateVirtualNode('$virtual_id', '$created_clone_div_id');"
    > [open] </a>
    <a href="javascript:;"
    onmousedown="DeleteVirtualNode('$created_clone_div_id');"
    > [close]</a></i></font>
    </legend>
    <div id="$created_clone_div_id">
    </div>
    </fieldset>

end_of_clone_sect

    # a DEBUG printout:
    #for (keys %chunks_id_hash) {print "[$_] => $chunks_id_hash{$_}<br>\n"}

    #<br>DEBUG: trying to clone [[$1]] whose id is [$virtual_id] 
    #OR [$chunks_id_hash{$name_of_linked_chunk}]

} # bus -- printing out formatted CHUNK_LINK cloning line


my $clonebody_cnt = 0; # to assign unique id's to divs to put clones in.

while ($chunkbuf =~ m!^(.*)$!gm ) { # -- line by line iteration over the doc as string in mem
    my $printed_line = $1;


if ($printed_line =~ m!^\s*\[\[LINKED_CHUNK(_\d+)?\s+(.*\S)\s*\]\]\s*<br>$!) { # -- CHUNK LINKS --

    my $name_of_linked_chunk = $2;

    unless ( exists $chunks_id_hash{$name_of_linked_chunk} ) {

print <<"end_of_clone_sect";
    <fieldset class='linked_chunk'>
    <legend class='linked_chunk_legend'>
    &lt;&lt;$name_of_linked_chunk&gt;&gt;<font color=darkred><sub><i>broken_link</i></sub></font>
    </legend>
    </fieldset>
end_of_clone_sect

    next;
    }

    if ($1) { # printing a single splinter LINKED_CHUNK_N of a given number

        my $splinter_cnt = (substr $1, 1);
        my $virtual_id = $chunks_id_hash{$name_of_linked_chunk}[$splinter_cnt-1]; 
        my $created_clone_div_id = "clonebody" . $clonebody_cnt;
        $clonebody_cnt++;

        my $shown_splinter_num = "(" . $splinter_cnt . ")" ;

        print_chunk_link($name_of_linked_chunk, $virtual_id, $created_clone_div_id, $shown_splinter_num);

    }
    else { # regular case: printing all splinters of a LINKED_CHUNK
        for (my $splinter_cnt=0;
                exists $chunks_id_hash{$name_of_linked_chunk}[$splinter_cnt]; )
        {

        my $virtual_id = $chunks_id_hash{$name_of_linked_chunk}[$splinter_cnt++];   
        my $created_clone_div_id = "clonebody" . $clonebody_cnt;
        $clonebody_cnt++;

        my $shown_splinter_num = 
                "(" . $splinter_cnt . ")" 
                        if $splinter_cnt > 1;

        print_chunk_link($name_of_linked_chunk, $virtual_id, $created_clone_div_id, $shown_splinter_num);


        } # rof over chunk splinters

    } # fi-esle
    
} # fi treatment of LINKED_CHUNKs   


elsif ($printed_line =~ m!^(.*)\[\[FLINK\s+(.*\S)\s*\]\](.*)$!) { # --FLINKS--

    print $1;

    unless ( exists $headings_id_hash{$2} ) {
    print "<u><font color=blue>$2</font></u>";
    print "<font color=darkred><sup><b><i>broken_flink</i></b></sup></font><br>\n";
    next;
    }

    my $virtual_id_ancor = $headings_id_hash{$2};    # this works with sections
    my $virtual_id_ancor_href = "#" . $virtual_id_ancor; 
print <<"end_of_clone_sect";
        <a href="$virtual_id_ancor_href"
        onclick="open_all_above($virtual_id_ancor);" 
        ><i>($virtual_id_ancor)</i> $2<sup>flink</sup></a>
end_of_clone_sect

    print $3,"\n";

    # a DEBUG printout:
    #for (keys %headings_id_hash) {print "[$_] => $headings_id_hash{$_}<br>\n"}
    #<br>DEBUG: trying to clone [[$2]] whose id is [$virtual_id_ancor] 
    #OR [$headings_id_hash{$2}] and ancor is $virtual_id_ancor_href
} # fisle - end of FLINKs


else{ # -- BODY OF THE DOCUMENT--  no virtual links met. Just print
            print $printed_line, "\n"; 
} # 
} # eliwh - end of line-by-line iteration over the buffer string in memory 


# close the page
        print $html_body_table_end;
        

#--- END OF SCRIPT ---


exit;


FORESTRY:

$shift_by_numlevels = $replant_tree || 0;

while (<STDIN>) {

    #~  html headings -- /change var for raw/dotHTML switching/
    s/(\s*)($tag_open\+?h)(\d+)(.*?$tag_close)(.*)($tag_open\/h)(\d+)$tag_close/
        $1
        .$2.($3+$shift_by_numlevels).$4
        .$5
        .$6.($7+$shift_by_numlevels)."$tag_close"
    /ex;

    #~ vim folds - opening
    s/^(\{\{\{)(\d+)/$1.($2+$shift_by_numlevels)/e;
    #~ vim folds - closing
    s/^(\}\}\})(\d+)/$1.($2+$shift_by_numlevels)/e;

    print;

} # elihw

close LITSOURCE;
exit;

# just in case:
exit;

# END OF SCRIPT

