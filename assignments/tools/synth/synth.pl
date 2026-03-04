#!/usr/bin/perl

use strict;
use Getopt::Long;

my @files;
my $files_csv;
my $list_of_files_filename;
my $fm;
my $dm;
my $em;
my $mm;
my $wbm;
my $what_to_do;
my $design_type;
my $synth_cmds;
my $top_module;
my $optimize="no";
my $all_files=0;

my $proc_top_module = "proc";

my @special_files;

push @special_files, "memory2c.v";
push @special_files, "memory2c_aligned.v";
push @special_files, "memory1c.v";
push @special_files, "memc.v";
push @special_files, "memv.v";
push @special_files, "final_memory.v";

define_synth_cmds();

GetOptions ("files=s" => \$files_csv,
            "list=s" => \$list_of_files_filename,
            "f=s" => \$fm,
            "d=s" => \$dm,
            "e=s" => \$em,
            "m=s" => \$mm,
            "wb=s" => \$wbm,
            "cmd=s" => \$what_to_do,
            "type=s" => \$design_type,
            "top=s" => \$top_module,
            "opt=s" => \$optimize,
            "all" => \$all_files);

check_sanity();
check_env_setup();

my $main_string == "";
my $flatten_string = "";
mkdir("synth");
create_tcl_file();
execute_tcl_file();

sub execute_tcl_file() {
  print "Cleaning temporary directory WORK\n";
  `rm -rf WORK`;
  print "Executing synth.tcl on Synopsys DC Compiler\n";
  if ($what_to_do eq "CHECK") {
    print "This phase does not do any optimizations\n";
  } else {
    print "This phase does optimizations, so will take some time\n";
  }
  my $cmd="dc_shell-t -f synth/synth.tcl | tee synth/synth.log";
  system($cmd);
  print "************************************************\n";
  print "Synthesis messages saved in synth.log.\nSynthesized files are in synth/$top_module.syn.v\n";
  print "Subset of errors found follow\n";
  print "---begin\n";
  $cmd ="egrep \"unresolved|Error|LINK\" synth/synth.log";
  system($cmd);
  print "---end\n";
  print "Cleaning temporary directory WORK\n";
  `rm -rf WORK`;
  print "Look for files in synth/\n";
}

sub create_tcl_file() {

  print "Creating synth.tcl\n";

  if ($all_files) {
    opendir(DIR, ".");
    @files = grep {  (/.v$/) && (!/_hier.v$/) &&  (!/clkrst.v$/) && (!/.*bench.*.v$/) && -f "$_" } readdir(DIR);
    closedir DIR;
  } elsif (defined $list_of_files_filename) {
    open(F1, $list_of_files_filename) || die "Cannot read $list_of_files_filename\n";
    @files=<F1>;
    close F1;
  } else {
    @files = split(/,/, $files_csv);
  }
  
  print "File list @files\n";

  chomp @files;

  foreach my $a (@files) {
    if ( ($a =~ /_hier.v/) || ($a eq "clkrst.v") || ($a =~ /_bench.v/) ) {
      die "Found a _hier.v, _bench.v file ($a) or clkrst.v\n";
    }
  }


  my $file_list="";
  foreach my $a (@files) {
    foreach my $b (@special_files) {
      my $rep_file = $a;
      $rep_file =~ s/\.v/\.syn\.v/;
      if ($a eq $b) {
        print "Memory-related module found...replacing $a with $rep_file\n";
        $a = $rep_file;
        if ( ! -e $a ) {
          print "$a file not found. Did you copy all the .syn.v files also?\n";
          exit (-1);
        }
      }
    }
    $file_list .= "$a ";
  }

  $main_string .= "echo \"********** CS147 Reading files begin ********************\"\n";  
  $main_string .= "set my_verilog_files [list $file_list ]\n";
  $main_string .= "set my_toplevel $top_module\n";
  $main_string .= "define_design_lib WORK -path ./WORK\n";
  $main_string .= "analyze -f verilog \$my_verilog_files\n";
  $main_string .= "elaborate \$my_toplevel -architecture verilog\n";
  $main_string .= "echo \"********** CS147 Reading files end ********************\"\n";  

  open(F1, ">synth/synth.tcl");

  if ($what_to_do =~ /SYNTH/) {
    if ($design_type =~ /PROC/) {
      proc_synth_cmds();
    } else {
      other_synth_cmds();
    }
    print F1 $main_string;
    print F1 $synth_cmds;
  } elsif ($what_to_do =~ /CHECK/) {
    $main_string .= "echo \"********** CS147 Linking all modules begin ********************\"\n";
    $main_string .= "link\n";
    $main_string .= "echo \"********** CS147 Linking all modules end **********************\"\n";
    $main_string .= "echo \"********** CS147 Checking design of all modules begin**********\"\n";
    $main_string .= "check_design\n";
    $main_string .= "echo \"********** CS147 Checking design of all modules end************\"\n";
    $main_string .= "report_hierarchy > synth/hierarchy.txt\n";
    $main_string .= "set filename [format \"%s%s\"  \$my_toplevel \".syn.v\"]\n";
    $main_string .= "write -f verilog \$my_toplevel -output synth/\$filename -hierarchy\n";
    $main_string .= "quit\n";
    print F1 $main_string;
  }
  close(F1);
}


sub proc_synth_cmds() {
 
  my @modules;
  push @modules, $fm;
  push @modules, $dm;
  push @modules, $em;
  push @modules, $mm;
  push @modules, $wbm;

  if ($optimize eq "yes") {
    foreach my $a (@modules) {
      $flatten_string .= "current_design $a\n";
      $flatten_string .= "ungroup -all -flatten\n";
    }

    $main_string .= $flatten_string;

    my $dont_touch_string = "";
    foreach my $a (@modules) {
      $dont_touch_string .= "set_dont_touch $a\n";
    }
  
    $main_string .= $dont_touch_string;
    
    $main_string .= "current_design proc\n";

    $main_string .= "ungroup -all -flatten\n";

    my $touch_string = "";
    foreach my $a (@modules) {
      $touch_string .= "set_dont_touch $a false\n";
    }
    $main_string .= $touch_string;
  } else {
    $main_string .= "current_design proc\n";
  }
}


sub other_synth_cmds() {
  $main_string .= "current_design \$my_toplevel\n";
  if ($optimize eq "yes") {
    $main_string .= "ungroup -all -flatten\n";
  }
}


sub check_sanity() {
  if (!$all_files) {
    if (!$list_of_files_filename) {
      if (!$files_csv) {
        print_help("Need to specify files with -files= or provide with -list");
        exit(-1);
      }
    } else {
      if ($files_csv) {
        print_help("Cannot specify both -list and -files\n");
        exit(-1);
      }
    }
  }

  if(  (!defined $design_type)
       || (!defined $what_to_do) ) {
    print_help("--type or --cmd is missing\n");
    exit(-1);
  }
  $what_to_do = uc($what_to_do);
  $design_type = uc($design_type);

  if ($design_type ne "PROC") {
    if (!defined $top_module) {
      print_help("Need top module name\n"); exit(-1);
    }
  } else {
    $top_module = $proc_top_module;
  }
  if ( ($what_to_do eq "CHECK") 
       || ($what_to_do eq "SYNTH") ) {
    if ($design_type eq "PROC") {
      if ( (defined $fm) 
           && (defined $dm) 
           && (defined $em) 
           && (defined $mm) 
           && (defined $wbm)  ) {
        if ($top_module ne "proc") {
          print_help("Unrecognized top module $top_module\nWhen synthesizing processor top module must be proc.\nUse type=other\n");
          exit(-1)
        }
      } else {
        print_help("Define fetch, decode, execute, memory, and write_back module names");
        exit(-1)
      }
      return;
    }
    if ($design_type eq "OTHER") {
      return;
    }
  } else {
    print_help("Unrecognized cmd $what_to_do\n");
    exit(-1);
  }

}

sub define_synth_cmds() {
  $synth_cmds=<<HERE
#/* The name of the clock pin. If no clock-pin     */
#/* exists, pick anything                          */
set my_clock_pin clk

#/* Target frequency in MHz for optimization       */
set my_clk_freq_MHz 1000

#/* Delay of input signals (Clock-to-Q, Package etc.)  */
set my_input_delay_ns 0.1

#/* Reserved time for output signals (Holdtime etc.)   */
set my_output_delay_ns 0.1


#/**************************************************/
#/* No modifications needed below                  */
#/**************************************************/
set verilogout_show_unconnected_pins "true"


# analyze -f verilog \$my_verilog_files
# elaborate \$my_toplevel -architecture verilog
# current_design \$my_toplevel

report_hierarchy 
link
uniquify

set my_period [expr 1000 / \$my_clk_freq_MHz]

set find_clock [ find port [list \$my_clock_pin] ]
if {  \$find_clock != [list] } {
   set clk_name \$my_clock_pin
   create_clock -period \$my_period \$clk_name
} else {
   set clk_name vclk
   create_clock -period \$my_period -name \$clk_name
} 

set_driving_cell  -lib_cell INVX1  [all_inputs]
set_input_delay \$my_input_delay_ns -clock \$clk_name [remove_from_collection [all_inputs] \$my_clock_pin]
set_output_delay \$my_output_delay_ns -clock \$clk_name [all_outputs]

compile 

check_design -summary

set filename [format "%s%s"  \$my_toplevel ".syn.v"]
write -hierarchy -f verilog \$my_toplevel -output synth/\$filename
set filename [format "%s%s"  \$my_toplevel ".ddc"]
write -hierarchy -format ddc -output synth/\$filename

report_hierarchy > synth/hierarchy.txt
report_reference > synth/reference_report.txt
report_area > synth/area_report.txt
report_cell > synth/cell_report.txt
report_timing -max_paths 20 > synth/timing_report.txt
report_power > synth/power_report.txt

quit

HERE

}


sub print_help() {
  my $err_string = shift(@_);
  my $usage_string;

  $usage_string=<<FOO;

Usage: synth.pl [options]

    Options:

     [-cmd <check|synth>] What to do:
                              check = just check if everything is ok
                              synth = perform synthesis (will take longer)
     [-type <other|proc>] What is the design:
                              proc = This is the processor. 
                                     Use when synthesizing the full processor
                                     then -f, -d, -e, -m, -wb must be specified
                              other = Some other design (use for hw, caches etc.)
     [-top <module name>] Name of the top-most module in your design. This
                          must be module instantiated inside the _hier level.
                          **You cannot specify the _hier module here*
     [-opt <yes|no> ]     Optimize the design yes or no. [Default = no]
     [-list <filename> ]  <filename> has a list of verilog files which make up 
                          your design. 
     [-file <f0,f1,f2,..> ] Provide a comma-separated list of verilog file names.


     Only one of -list or -file can be used

     [-f <fetch module]   Name of your fetch module, 
                          required if type=proc, else ignored

     [-d <fetch module]   Name of your decode module, 
                          required if type=proc, else ignored
     [-e <fetch module]   Name of your execute module, 
                          required if type=proc, else ignored
     [-m <fetch module]   Name of your memory module, 
                          required if type=proc, else ignored
     [-wb <fetch module]  Name of your write-back module, 
                          required if type=proc, else ignored

Output:

     If cmd=check
       synth/synth.log      Detailed log of synthesis 
       synth/hiearchy.txt   Hieararchy of your design
       synth/<top>.syn.v    Gate-level version of your design
                            All modules will be in ONE single
                            verilog file. Replace top with the
                            top module name you specified
                            as input.
     
    If cmd=synth
       The above two files, PLUS
   
     synth/reference_report.txt  Detailed usage of each module
     synth/area_report.txt       Detailed area report
     synth/timing_report.txt     Detailed timing report

Example usages:

Checking the ALU from hw2/problem2

prompt> synth.pl --file=foo.v,mux.v,cla4.v,alu.v --type=other --cmd=check --top=alu 

Same as above using the -list option. Create a 
file file_list with the following:

foo.v
mux.v
cla4.v
alu.v

prompt> synth.pl --file=file_list --type=other --cmd=check --top=alu 



Synthesizing the ALU from hw2/problem2

prompt> synth.pl --file=foo.v,mux.v,cla4.v,alu.v --type=other --cmd=check --top=alu 

Checking the full processor for demo2

prompt> synth.pl --file=foo --type=proc --cmd=check --top=proc
 -f=fetch -d=decode -e=execute -m=memory -wb=write_back

Assumes your fetch module is called fetch, decode module
is called decode etc.


FOO

  print $usage_string;

  print "----------------------------Error---------------------\n";
  print "$err_string\n";
}


sub check_env_setup() {
  my $cmd="dc_shell-t -version";
  my $out=`$cmd`;
  if ($out =~ /dc_shell version/) {
  } else {
    die "Cannot execute dc_shell-t. Something is wrong.\nDid you perform all the environment setup steps?\n";
  }
}
