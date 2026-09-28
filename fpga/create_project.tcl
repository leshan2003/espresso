# vivado -mode batch -source fpga/create_project.tcl -tclargs espresso
# Run from any directory. Builds remain outside the source folders.
set root [file normalize [file join [file dirname [info script]] ..]]
set variant espresso
if {$argc > 0} { set variant [lindex $argv 0] }
switch -- $variant {
    espresso { set top FD_top }
    scheduler { set top EventScheduler5 }
    accsrc { set top FD_top }
    default { error "Choose espresso, scheduler, or accsrc" }
}
set source_dir [file join $root verilog design $variant]
set simulation_dir [file join $root verilog simulation $variant]
set output [file join $root build vivado $variant]
if {[file exists [file join $output ${variant}.xpr]]} {
    error "Project already exists: $output; open it instead of overwriting it."
}
create_project $variant $output -part xczu7ev-ffvc1156-2-e
add_files [glob [file join $source_dir *.v]]
set simulation_files [glob -nocomplain [file join $simulation_dir *.v]]
if {[llength $simulation_files] > 0} {
    add_files -fileset sim_1 $simulation_files
}
set_property top $top [current_fileset]
if {$variant eq "accsrc"} {
    set_property top fd_top_tb [get_filesets sim_1]
}
set_property -dict [list xsim.compile.xvlog.more_options {--relax} \
    xsim.elaborate.xelab.more_options {--relax}] [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
# Deliberately no implementation run: board pins and timing constraints must be
# supplied for the target design. The archived projects had no reusable XDC set.
puts "Created $variant with top $top in $output"
