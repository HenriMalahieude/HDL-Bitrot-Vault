`timescale 1ns / 100ps
`define CLK_PERIOD 10ns

//Xilinx niceties, make sure to add the IP and **GENERATE** the files for the
//project. Otherwise you will get a nice error telling you it doesn't exist
import axi_vip_pkg::*;
import axi_vip_0_pkg::*;
import axi_vip_1_pkg::*;

module tb_comb_finj_fp(); //NOTE: Difference with base is that it tests the partial channel and fixed injections

	reg clk;
	reg rstl;
	reg fault_en;
	reg fault_det_in;

	wire inj_force;
	wire [1:0] inj_type;

	initial begin
		clk = 0;
		forever #(`CLK_PERIOD / 2) clk = ~clk;
	end

	//Connect to the follower
	wire [12:0] 	flwr_awid;
	wire [31:0] 	flwr_awaddr; //inj here
	wire [7:0] 		flwr_awlen;
	wire [2:0] 		flwr_awsize;
	wire [1:0] 		flwr_awburst;
	wire 			flwr_awvalid;
	reg				flwr_awready;

	wire [31:0]		flwr_wdata; //inj here
	wire [3:0]		flwr_wstrb;
	wire			flwr_wlast;
	wire			flwr_wvalid;
	reg 			flwr_wready;

	reg [12:0] 		flwr_bid;
	reg [1:0] 		flwr_bresp;
	reg 			flwr_bvalid;
	wire			flwr_bready;

	wire [12:0] 	flwr_arid;
	wire [31:0] 	flwr_araddr; //inj here
	wire [7:0] 	    flwr_arlen;
	wire [2:0] 	    flwr_arsize;
	wire [1:0] 	    flwr_arburst;
	wire			flwr_arvalid;
	reg				flwr_arready;

	reg [12:0] 		flwr_rid;
	reg [31:0]		flwr_rdata; //inj here
	reg [1:0] 		flwr_rresp;
	reg				flwr_rlast;
	reg				flwr_rvalid;
	wire			flwr_rready;

	//Downstream side (output) (follower)
	axi_vip_0 flwr_vip(
		.aclk(clk),
		.aresetn(rstl),

		.s_axi_araddr(flwr_araddr),
		.s_axi_arburst(flwr_arburst),
		.s_axi_arid(flwr_arid),
		.s_axi_arlen(flwr_arlen),
		.s_axi_arsize(flwr_arsize),
		.s_axi_arvalid(flwr_arvalid),
		.s_axi_arready(flwr_arready),
		.s_axi_awaddr(flwr_awaddr),
		.s_axi_awburst(flwr_awburst),
		.s_axi_awid(flwr_awid),
		.s_axi_awlen(flwr_awlen),
		.s_axi_awsize(flwr_awsize),
		.s_axi_awvalid(flwr_awvalid),
		.s_axi_awready(flwr_awready),
		.s_axi_bid(flwr_bid),
		.s_axi_bready(flwr_bready),
		.s_axi_bvalid(flwr_bvalid),
		.s_axi_bresp(flwr_bresp),
		.s_axi_rready(flwr_rready),
		.s_axi_rdata(flwr_rdata),
		.s_axi_rid(flwr_rid),
		.s_axi_rlast(flwr_rlast),
		.s_axi_rresp(flwr_rresp),
		.s_axi_rvalid(flwr_rvalid),
		.s_axi_wdata(flwr_wdata),
		.s_axi_wlast(flwr_wlast),
		.s_axi_wstrb(flwr_wstrb),
		.s_axi_wvalid(flwr_wvalid),
		.s_axi_wready(flwr_wready)
	);

	//begin verifier int mem mode (save the writes)
	axi_vip_0_slv_mem_t flwr_vip_agent;
	initial begin
		flwr_vip_agent = new("seup vip mem agent", tb_comb_finj_fp.flwr_vip.inst.IF);
		flwr_vip_agent.start_slave();
	end

	//Upstream (input) side axi
	reg [12:0]  up_awid;
	reg [31:0]  up_awaddr; //inj here
	reg [7:0] 	up_awlen;
	reg [2:0] 	up_awsize;
	reg [1:0] 	up_awburst;
	reg 		up_awvalid;
	wire	    up_awready;

	reg [31:0]	up_wdata; //inj here
	reg [3:0]	up_wstrb;
	reg			up_wlast;
	reg			up_wvalid;
	wire 		up_wready;

	wire [12:0] up_bid;
	wire [1:0] 	up_bresp;
	wire 		up_bvalid;
	reg			up_bready;

	reg [12:0] 	up_arid;
	reg [31:0] 	up_araddr; //inj here
	reg [7:0] 	up_arlen;
	reg [2:0] 	up_arsize;
	reg [1:0] 	up_arburst;
	reg			up_arvalid;
	wire		up_arready;

	wire [12:0] up_rid;
	wire [31:0]	up_rdata; //inj here
	wire [1:0] 	up_rresp;
	wire		up_rlast;
	wire		up_rvalid;
	reg			up_rready;

	//Upstream side (input) (leader)
	axi_vip_1 up_vip(
		.aclk(clk),
		.aresetn(rstl),

		.m_axi_araddr(up_araddr),
		.m_axi_arburst(up_arburst),
		.m_axi_arid(up_arid),
		.m_axi_arlen(up_arlen),
		.m_axi_arsize(up_arsize),
		.m_axi_arvalid(up_arvalid),
		.m_axi_arready(up_arready),
		.m_axi_awaddr(up_awaddr),
		.m_axi_awburst(up_awburst),
		.m_axi_awid(up_awid),
		.m_axi_awlen(up_awlen),
		.m_axi_awsize(up_awsize),
		.m_axi_awvalid(up_awvalid),
		.m_axi_awready(up_awready),
		.m_axi_bid(up_bid),
		.m_axi_bready(up_bready),
		.m_axi_bvalid(up_bvalid),
		.m_axi_bresp(up_bresp),
		.m_axi_rready(up_rready),
		.m_axi_rdata(up_rdata),
		.m_axi_rid(up_rid),
		.m_axi_rlast(up_rlast),
		.m_axi_rresp(up_rresp),
		.m_axi_rvalid(up_rvalid),
		.m_axi_wdata(up_wdata),
		.m_axi_wlast(up_wlast),
		.m_axi_wstrb(up_wstrb),
		.m_axi_wvalid(up_wvalid),
		.m_axi_wready(up_wready)
	);

	//begin verifier
	axi_vip_1_mst_t up_vip_agent;
	initial begin
		up_vip_agent = new("up vip mem agent", tb_comb_finj_fp.up_vip.inst.IF);
		up_vip_agent.start_master();
	end

	comb_finj #( //Standard device testing
			.CONTINUOUS_INJ_EN(1),
			.FI_FIXED(1),
			.FIXED_INJ(32'hFF00),
			.FI_RDATA_EN(0),
			.FI_WDATA_EN(0),
			.FI_RADDR_EN(1),
			.FI_WADDR_EN(1)
		) dut (
		.aclk(clk),
		.aresetn(rstl),
		.fault_en(fault_en),
		.fault_det_in(fault_det_in),
		.inj_force(inj_force),
		.inj_type(inj_type),

		.m_awid(flwr_awid),
		.m_awaddr(flwr_awaddr),
		.m_awlen(flwr_awlen),
		.m_awsize(flwr_awsize),
		.m_awburst(flwr_awburst),
		.m_awvalid(flwr_awvalid),
		.m_awready(flwr_awready),
		.m_wdata(flwr_wdata),
		.m_wstrb(flwr_wstrb),
		.m_wlast(flwr_wlast),
		.m_wvalid(flwr_wvalid),
		.m_wready(flwr_wready),
		.m_bid(flwr_bid),
		.m_bresp(flwr_bresp),
		.m_bvalid(flwr_bvalid),
		.m_bready(flwr_bready),
		.m_arid(flwr_arid),
		.m_araddr(flwr_araddr),
		.m_arlen(flwr_arlen),
		.m_arsize(flwr_arsize),
		.m_arburst(flwr_arburst),
		.m_arvalid(flwr_arvalid),
		.m_arready(flwr_arready),
		.m_rid(flwr_rid),
		.m_rdata(flwr_rdata),
		.m_rresp(flwr_rresp),
		.m_rlast(flwr_rlast),
		.m_rvalid(flwr_rvalid),
		.m_rready(flwr_rready),

		.s_awid(up_awid),
		.s_awaddr(up_awaddr),
		.s_awlen(up_awlen),
		.s_awsize(up_awsize),
		.s_awburst(up_awburst),
		.s_awvalid(up_awvalid),
		.s_awready(up_awready),
		.s_wdata(up_wdata),
		.s_wstrb(up_wstrb),
		.s_wlast(up_wlast),
		.s_wvalid(up_wvalid),
		.s_wready(up_wready),
		.s_bid(up_bid),
		.s_bresp(up_bresp),
		.s_bvalid(up_bvalid),
		.s_bready(up_bready),
		.s_arid(up_arid),
		.s_araddr(up_araddr),
		.s_arlen(up_arlen),
		.s_arsize(up_arsize),
		.s_arburst(up_arburst),
		.s_arvalid(up_arvalid),
		.s_arready(up_arready),
		.s_rid(up_rid),
		.s_rdata(up_rdata),
		.s_rresp(up_rresp),
		.s_rlast(up_rlast),
		.s_rvalid(up_rvalid),
		.s_rready(up_rready)
	);

	//sample datas
	wire [255:0] data_blocks [0:7] = {
		{
		128'h3f3e3d3c3b3a39383736353433323130,
		128'h2f2e2d2c2b2a29282726252423222120
		},
		{
		128'h1f1e1d1c1b1a19181716151413121110,
		128'h0f0e0d0c0b0a09080706050403020100
		},
		{
		128'h4f4e4d4c4b4a49484746454443424140,
		128'h5f5e5d5c5b5a59585756555453525150
		},
		{
		128'h6f6e6d6c6b6a69686766656463626160,
		128'h7f7e7d7c7b7a79787776757473727170
		},
		{
		128'h8f8e8d8c8b8a89888786858483828180,
		128'h9f9e9d9c9b9a99989796959493929190
		},
		{
		128'hafaeadacabaaa9a8a7a6a5a4a3a2a1a0,
		128'hbfbebdbcbbbab9b8b7b6b5b4b3b2b1b0
		},
		{
		128'hcfcecdcccbcac9c8c7c6c5c4c3c2c1c0,
		128'hdfdedddcdbdad9d8d7d6d5d4d3d2d1d0
		},
		{
		128'hefeeedecebeae9e8e7e6e5e4e3e2e1e0,
		128'hfffefdfcfbfaf9f8f7f6f5f4f3f2f1f0
		}
	};

	xil_axi_size_t common_size = 3'b010;
	xil_axi_burst_t common_burst = XIL_AXI_BURST_TYPE_INCR;
	xil_axi_uint common_txid = 0;
	xil_axi_len_t tx_len = 0;

	task automatic do_write_tx(
		input string name,
		input xil_axi_ulong addr,
		input bit [255:0] data,
		input xil_axi_len_t len,
		ref xil_axi_uint txid,
		input bit wait_complete = 1
	);

		axi_transaction wr_tx;
		wr_tx = up_vip_agent.wr_driver.create_transaction(name);
		wr_tx.set_write_cmd(addr, common_burst, txid[12:0], len, common_size);

		wr_tx.set_data_block(data);
		up_vip_agent.wr_driver.send(wr_tx);
		if (wait_complete) begin
			up_vip_agent.wr_driver.wait_driver_idle();
		end

		$display("%s write @ addr 0x%h id %d len %d",
			wait_complete ? "Completed" : "Initiated",
			addr, txid, len);
		txid = txid + 1;
	endtask

	task automatic do_read_tx(
		input string name,
		input xil_axi_ulong addr,
		input bit [255:0] expected,
		input xil_axi_len_t len,
		ref xil_axi_uint txid,
		input bit faulty = 0
	);

		axi_transaction rd_tx;
		rd_tx = up_vip_agent.rd_driver.create_transaction(name);
		rd_tx.set_read_cmd(addr, common_burst, txid[12:0], len, common_size);
		rd_tx.set_driver_return_item();

		up_vip_agent.rd_driver.send(rd_tx);
		up_vip_agent.rd_driver.wait_rsp(rd_tx);

		if (len > 0) begin
			bit [255:0] resp_data;
			resp_data = rd_tx.get_data_block();
			if (!faulty) begin
				if (resp_data != expected) begin
					$fatal("Read mismatch from expected\n\tRX: 0x%h\n\tEX: 0x%h", resp_data, expected);
				end
			end else if (faulty) begin
				if (resp_data == expected) begin
					$fatal("Read matched expected despite injection?\n\tRX: 0x%h", resp_data);
				end else begin
					$display("Proper difference detected:\n\tRX: 0x%h\n\tEX: 0x%h", resp_data, expected);
				end
			end
			$display("Completed read @ addr 0x%h id %d len %d: 0x%h", addr, txid, len, resp_data);
		end else begin
			$display("Completed read @ addr 0x%h id %d len %d.", addr, txid, len);
		end

		txid = txid + 1;
	endtask

	//Main test loop
	reg [32:0] addr;
	initial begin
		$display("Reseting system");
		fault_en = 0;
		fault_det_in = 0;

		rstl = 1;
		#`CLK_PERIOD
		rstl = 0;
		#(`CLK_PERIOD * 16) //AXI Expects at least 16 clock cycles for this
		rstl = 1;

		$display("Testing simple ctrl signals");
		fault_en = 1;
		#(`CLK_PERIOD)
		if (inj_force != 1) begin
			$fatal("Force injection not high?");
		end
		if (inj_type != 2) begin
			$fatal("Injection type is not properly set?");
		end // */

		fault_en = 0;
		#(`CLK_PERIOD)
		if (inj_force != 1) begin
			$fatal("Force injection not high?(3)");
		end

		$display("Testing ctrl signal resets");
		fault_det_in = 1;
		#(`CLK_PERIOD)
		if (inj_force != 0) begin
			$fatal("Force injection not reset with fault_det_in");
		end
		if (inj_type != 3) begin
			$fatal("Injection type did not increment?");
		end // */

		fault_det_in = 0;
		fault_en = 1;
		#(`CLK_PERIOD)
		fault_en = 0;
		#(`CLK_PERIOD)
		if (inj_force != 1) begin
			$fatal("Force injection not high(2)?");
		end

		rstl = 0;
		#(`CLK_PERIOD * 16)
		rstl = 1;
		#(`CLK_PERIOD)

		if (inj_force != 0) begin
			$fatal("Force injection did not reset?");
		end
		if (inj_type != 2) begin
			$fatal("Injection type didn't reset");
		end // */

		$display("Testing AXI transactions, no faults");
		for (integer i = 0; i < 8; i = i + 1) begin
			$display("%d: Write instance", i);
			addr = i * 256;
			do_write_tx("w1", addr, data_blocks[i], 7, common_txid);
			#(`CLK_PERIOD)
			$display("%d: Read instance", i);
			do_read_tx("r1", addr, data_blocks[i], 7, common_txid);
		end

		$display("Testing AXI transactions, w/ faults");

		addr = ((2**32) - 1);
		addr = addr ^ 8'hff; //accessing anything shouldn't cross 256 boundary or something
		for (integer i = 0; i < 4; i = i + 1) begin
			fault_det_in = 0;
			fault_en = 1;
			#(`CLK_PERIOD * 3)
			fault_en = 0;
			if (inj_type != ((i % 2) + 2)) $fatal("Injection type is not properly set?");

			$display("%d: Write Instance", i);
			do_write_tx("w2", addr, data_blocks[i], 7, common_txid);
			#`CLK_PERIOD

			$display("%d: Read Instance", i);
			do_read_tx("r2", addr, data_blocks[i], 7, common_txid, 1);

			fault_det_in = 1;
			#(`CLK_PERIOD * 2)
			if (inj_force != 0) $fatal("Force injection did not reset?");
		end

		#(`CLK_PERIOD*16)
		$display("DONE");
		$finish;
	end

endmodule
