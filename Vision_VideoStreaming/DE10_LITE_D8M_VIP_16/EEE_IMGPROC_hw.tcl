# TCL File Generated by Component Editor 16.1
# Thu Jun 10 15:12:04 BST 2021
# DO NOT MODIFY


# 
# EEE_IMGPROC "EEE_IMGPROC" v1.0
#  2021.06.10.15:12:04
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module EEE_IMGPROC
# 
set_module_property DESCRIPTION ""
set_module_property NAME EEE_IMGPROC
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME EEE_IMGPROC
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL EEE_IMGPROC
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file EEE_IMGPROC.v VERILOG PATH ip/EEE_IMGPROC/EEE_IMGPROC.v TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_n reset_n Input 1


# 
# connection point avalon_streaming_sink
# 
add_interface avalon_streaming_sink avalon_streaming end
set_interface_property avalon_streaming_sink associatedClock clock
set_interface_property avalon_streaming_sink associatedReset reset
set_interface_property avalon_streaming_sink dataBitsPerSymbol 8
set_interface_property avalon_streaming_sink errorDescriptor ""
set_interface_property avalon_streaming_sink firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_sink maxChannel 0
set_interface_property avalon_streaming_sink readyLatency 1
set_interface_property avalon_streaming_sink ENABLED true
set_interface_property avalon_streaming_sink EXPORT_OF ""
set_interface_property avalon_streaming_sink PORT_NAME_MAP ""
set_interface_property avalon_streaming_sink CMSIS_SVD_VARIABLES ""
set_interface_property avalon_streaming_sink SVD_ADDRESS_GROUP ""

add_interface_port avalon_streaming_sink sink_data data Input 24
add_interface_port avalon_streaming_sink sink_valid valid Input 1
add_interface_port avalon_streaming_sink sink_ready ready Output 1
add_interface_port avalon_streaming_sink sink_sop startofpacket Input 1
add_interface_port avalon_streaming_sink sink_eop endofpacket Input 1


# 
# connection point avalon_streaming_source
# 
add_interface avalon_streaming_source avalon_streaming start
set_interface_property avalon_streaming_source associatedClock clock
set_interface_property avalon_streaming_source associatedReset reset
set_interface_property avalon_streaming_source dataBitsPerSymbol 8
set_interface_property avalon_streaming_source errorDescriptor ""
set_interface_property avalon_streaming_source firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_source maxChannel 0
set_interface_property avalon_streaming_source readyLatency 1
set_interface_property avalon_streaming_source ENABLED true
set_interface_property avalon_streaming_source EXPORT_OF ""
set_interface_property avalon_streaming_source PORT_NAME_MAP ""
set_interface_property avalon_streaming_source CMSIS_SVD_VARIABLES ""
set_interface_property avalon_streaming_source SVD_ADDRESS_GROUP ""

add_interface_port avalon_streaming_source source_data data Output 24
add_interface_port avalon_streaming_source source_eop endofpacket Output 1
add_interface_port avalon_streaming_source source_ready ready Input 1
add_interface_port avalon_streaming_source source_sop startofpacket Output 1
add_interface_port avalon_streaming_source source_valid valid Output 1


# 
# connection point s1
# 
add_interface s1 avalon end
set_interface_property s1 addressUnits WORDS
set_interface_property s1 associatedClock clock
set_interface_property s1 associatedReset reset
set_interface_property s1 bitsPerSymbol 8
set_interface_property s1 burstOnBurstBoundariesOnly false
set_interface_property s1 burstcountUnits WORDS
set_interface_property s1 explicitAddressSpan 0
set_interface_property s1 holdTime 0
set_interface_property s1 linewrapBursts false
set_interface_property s1 maximumPendingReadTransactions 0
set_interface_property s1 maximumPendingWriteTransactions 0
set_interface_property s1 readLatency 0
set_interface_property s1 readWaitTime 1
set_interface_property s1 setupTime 0
set_interface_property s1 timingUnits Cycles
set_interface_property s1 writeWaitTime 0
set_interface_property s1 ENABLED true
set_interface_property s1 EXPORT_OF ""
set_interface_property s1 PORT_NAME_MAP ""
set_interface_property s1 CMSIS_SVD_VARIABLES ""
set_interface_property s1 SVD_ADDRESS_GROUP ""

add_interface_port s1 s_chipselect chipselect Input 1
add_interface_port s1 s_read read Input 1
add_interface_port s1 s_write write Input 1
add_interface_port s1 s_readdata readdata Output 32
add_interface_port s1 s_writedata writedata Input 32
add_interface_port s1 s_address address Input 3
set_interface_assignment s1 embeddedsw.configuration.isFlash 0
set_interface_assignment s1 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s1 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s1 embeddedsw.configuration.isPrintableDevice 0


# 
# connection point conduit_mode
# 
add_interface conduit_mode conduit end
set_interface_property conduit_mode associatedClock clock
set_interface_property conduit_mode associatedReset ""
set_interface_property conduit_mode ENABLED true
set_interface_property conduit_mode EXPORT_OF ""
set_interface_property conduit_mode PORT_NAME_MAP ""
set_interface_property conduit_mode CMSIS_SVD_VARIABLES ""
set_interface_property conduit_mode SVD_ADDRESS_GROUP ""

add_interface_port conduit_mode mode new_signal Input 4

