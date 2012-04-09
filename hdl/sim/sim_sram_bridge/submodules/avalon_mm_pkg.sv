// (C) 2001-2012 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/11.1sp2/ip/sopc/components/verification/lib/avalon_mm_pkg.sv#1 $
// $Revision: #1 $
// $Date: 2011/11/10 $
//-----------------------------------------------------------------------------
// =head1 NAME
// avalon_mm_pkg
// =head1 SYNOPSIS
// Package for shared Avalon MM component types.
//-----------------------------------------------------------------------------
// =head1 COPYRIGHT
// Copyright (c) 2008 Altera Corporation. All Rights Reserved.
// The information contained in this file is the property of Altera
// Corporation. Except as specifically authorized in writing by Altera 
// Corporation, the holder of this file shall keep all information 
// contained herein confidential and shall protect same in whole or in part 
// from disclosure and dissemination to all third parties. Use of this 
// program confirms your agreement with the terms of this license.
//-----------------------------------------------------------------------------
// =head1 DESCRIPTION
// This package contains shared non-parameterized type definitions.
// =cut

`ifndef _AVALON_MM_PKG_
`define _AVALON_MM_PKG_

package avalon_mm_pkg;
   import verbosity_pkg::*;
   
   // Transaction request types
   typedef enum int {                    // public 
		     REQ_READ = 0,       // Read Request
                     REQ_WRITE = 1,      // Write Request
		     REQ_IDLE = 2        // Idle
                     } Request_t;

   // Slave BFM wait state logic operates in one of three distinct modes
   typedef enum int {          
		     WAIT_FIXED = 0,  // default: fixed wait cycles per burst cycle
                     WAIT_RANDOM = 1, // random  min =< wait cycles <= max
		     WAIT_ADDRESSABLE = 2 // fixed wait cycles per command address
                     } SlaveWaitMode_t;
   
   function automatic string request_string(Request_t request);
      case(request) 
     	REQ_READ: return("read");
     	REQ_WRITE: return("write");
     	REQ_IDLE: return("idle");
     	default: return("INVALID_REQUEST");
      endcase 
   endfunction

endpackage

`endif
   
