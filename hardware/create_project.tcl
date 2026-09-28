# vivado -mode batch -source hardware/create_project.tcl -tclargs espresso
# Run from any directory. Builds remain outside the source folders.
set root [file normalize [file join [file dirname [info script]] ..]]
set variant espresso
if {$argc > 0} { set variant [lindex $argv 0] }
switch -- $variant {
    espresso { set source_dir hardware/espresso/rtl; set top FD_top }
    scheduler { set source_dir hardware/scheduler/rtl; set top EventScheduler5 }
    accsrc { set source_dir hardware/accsrc/design_sources; set top FD_top }
    default { error "Choose espresso, scheduler, or accsrc" }
}
set output [file join $root build vivado $variant]
if {[file exists [file join $output ${variant}.xpr]]} {
    error "Project already exists: $output; open it instead of overwriting it."
}
create_project $variant $output -part xczu7ev-ffvc1156-2-e
add_files [glob [file join $root $source_dir *.v]]
set_property top $top [current_fileset]
set_property -dict [list xsim.compile.xvlog.more_options {--relax} \
    xsim.elaborate.xelab.more_options {--relax}] [get_filesets sim_1]
update_compile_order -fileset sources_1
# Deliberately no implementation run: board pins and timing constraints must be
# supplied for the target design. The archived projects had no reusable XDC set.
puts "Created $variant with top $top in $output"
