`timescale 1ns / 100ps

module comb_finj #(

	parameter FI_RDATA_EN = 1, 		//Enable fault injection on read data channel
	parameter FI_WDATA_EN = 1, 		//Enable fault injection on write data channel
	parameter FI_RADDR_EN = 1, 		//Enable fault injection on read addr channel
	parameter FI_WADDR_EN = 1, 		//Enable fault injection on write addr channel
	parameter FI_FIXED = 0,			//Do not change the location of the bit flip
	parameter INJ_FLIP_DEF = 32'hFF	//If Fixed, where to inject the bit flip. Ignored otherwise

	)(

	input aclk,
	input aresetn,

	input fault_en, //the button
	input fault_det_in, //disable fault injection

	output reg inj_force, //actively injecting at the moment
	output reg [1:0] inj_type,
	output reg [31:0] flipper, //which bits are gonna flip

	//Following the transaction
	output reg [12:0] 	m_awid,
	output reg [31:0] 	m_awaddr, //inj here
	output reg [7:0] 	m_awlen,
	output reg [2:0] 	m_awsize,
	output reg [1:0] 	m_awburst,
	output reg 			m_awvalid,
	input				m_awready,

	output reg [31:0]	m_wdata, //inj here
	output reg [3:0]	m_wstrb,
	output reg			m_wlast,
	output reg			m_wvalid,
	input 				m_wready,

	input [12:0] 		m_bid,
	input [1:0] 		m_bresp,
	input 				m_bvalid,
	output reg			m_bready,

	output reg [12:0] 	m_arid,
	output reg [31:0] 	m_araddr, //inj here
	output reg [7:0] 	m_arlen,
	output reg [2:0] 	m_arsize,
	output reg [1:0] 	m_arburst,
	output reg			m_arvalid,
	input				m_arready,

	input [12:0] 		m_rid,
	input [31:0]		m_rdata, //inj here
	input [1:0] 		m_rresp,
	input				m_rlast,
	input				m_rvalid,
	output reg			m_rready,

	//Leading the transaction
	input [12:0] 		s_awid,
	input [31:0] 		s_awaddr,
	input [7:0] 		s_awlen,
	input [2:0] 		s_awsize,
	input [1:0] 		s_awburst,
	input 				s_awvalid,
	output reg			s_awready,

	input [31:0]		s_wdata,
	input [3:0]			s_wstrb,
	input 				s_wlast,
	input 				s_wvalid,
	output reg			s_wready,

	output reg [12:0] 	s_bid,
	output reg [1:0] 	s_bresp,
	output reg 			s_bvalid,
	input				s_bready,

	input [12:0] 		s_arid,
	input [31:0] 		s_araddr,
	input [7:0] 		s_arlen,
	input [2:0] 		s_arsize,
	input [1:0] 		s_arburst,
	input 				s_arvalid,
	output reg			s_arready,

	output reg [12:0] 	s_rid,
	output reg [31:0]	s_rdata,
	output reg [1:0] 	s_rresp,
	output reg			s_rlast,
	output reg			s_rvalid,
	input				s_rready
);

//////////////////////// Fault Injector ////////////////////////
//Register holding the bit that will flip
if (FI_FIXED) begin
	initial begin
		flipper = INJ_FLIP_DEF;
	end
end else begin
	always @(posedge aclk) begin
		if (!aresetn || flipper == 0) begin
			flipper = 32'h1;
		end else begin
			flipper = (flipper << 1);
		end
	end // */
end

//Force a fault injection until the error is detected
always @(posedge aclk) begin
	if (!aresetn || fault_det_in) begin
		inj_force = 0;
	end else begin
		if (fault_en) inj_force = 1;
	end
end

//things we'll inject on
reg [31:0] lcl_araddr;
reg [31:0] lcl_awaddr;
reg [31:0] lcl_rdata;
reg [31:0] lcl_wdata;

localparam INJ_RDATA = 0, INJ_WDATA = 1, INJ_WADDR = 2, INJ_RADDR = 3;
always @(posedge aclk) begin
	if (!aresetn) begin
		if 		(FI_RDATA_EN) inj_type = INJ_RDATA;
		else if (FI_WDATA_EN) inj_type = INJ_WDATA;
		else if (FI_WADDR_EN) inj_type = INJ_WADDR;
		else 				  inj_type = INJ_RADDR;
	end else if (fault_det_in) begin
		case (inj_type)
			INJ_RDATA: begin
				if 		(FI_WDATA_EN) inj_type = INJ_WDATA;
				else if (FI_WADDR_EN) inj_type = INJ_WADDR;
				else if (FI_RADDR_EN) inj_type = INJ_RADDR;
				else 				  inj_type = INJ_RDATA;
			end
			INJ_WDATA: begin
				if 		(FI_WADDR_EN) inj_type = INJ_WADDR;
				else if (FI_RADDR_EN) inj_type = INJ_RADDR;
				else if (FI_RDATA_EN) inj_type = INJ_RDATA;
				else 				  inj_type = INJ_WDATA;
			end
			INJ_WADDR: begin
				if 		(FI_RADDR_EN) inj_type = INJ_RADDR;
				else if (FI_RDATA_EN) inj_type = INJ_RDATA;
				else if (FI_WDATA_EN) inj_type = INJ_WDATA;
				else 				  inj_type = INJ_WADDR;
			end
			INJ_RADDR: begin
				if 		(FI_RDATA_EN) inj_type = INJ_RDATA;
				else if (FI_WDATA_EN) inj_type = INJ_WDATA;
				else if (FI_WADDR_EN) inj_type = INJ_WADDR;
				else 				  inj_type = INJ_RADDR;
			end
		endcase
	end
end // */

//////////////////////// AXI Channel SMs ////////////////////////
localparam ST_IDLE = 0, ST_SEND = 1;

//Per Channel State
reg	aw_st, aw_nxt;
reg	w_st, w_nxt;
reg	b_st, b_nxt;
reg	ar_st, ar_nxt;
reg	r_st, r_nxt;

always @(posedge aclk) begin
	if (!aresetn) begin
		aw_st = ST_IDLE;
		w_st = ST_IDLE;
		b_st = ST_IDLE;
		ar_st = ST_IDLE;
		r_st = ST_IDLE;
	end else begin
		aw_st	= aw_nxt;
		w_st	=  w_nxt;
		b_st	=  b_nxt;
		ar_st	= ar_nxt;
		r_st	=  r_nxt;
	end
end

//Write Request Channel
always @(*) begin
	m_awid 		= 0;
	m_awaddr 	= 0;
	m_awlen		= 0;
	m_awsize	= 0;
	m_awburst	= 0;
	m_awvalid	= 0;
	s_awready	= 0;

	case (aw_st)
		ST_IDLE: begin
			aw_nxt = ST_IDLE;

			if (s_awvalid) begin
				aw_nxt = ST_SEND;
				if (FI_WADDR_EN) begin
					if (inj_force && inj_type == INJ_WADDR) begin
						lcl_awaddr = (s_awaddr ^ flipper);
					end else begin
						lcl_awaddr = s_awaddr;
					end // */
				end
			end
		end
		ST_SEND: begin
			aw_nxt = ST_SEND;

			m_awid 		= s_awid;
			if (FI_WADDR_EN) m_awaddr = lcl_awaddr;
			else			 m_awaddr = s_awaddr;
			m_awlen		= s_awlen;
			m_awsize	= s_awsize;
			m_awburst	= s_awburst;
			m_awvalid	= s_awvalid;

			if (m_awready) begin
				s_awready = m_awready;
				aw_nxt = ST_IDLE;
			end
		end
	endcase
end

//Write Data Channel
always @(*) begin
	m_wdata 	= 0;
	m_wstrb 	= 0;
	m_wlast		= 0;
	m_wvalid	= 0;
	s_wready	= 0;

	case (w_st)
		ST_IDLE: begin
			w_nxt = ST_IDLE;
			if (s_wvalid) begin
				w_nxt = ST_SEND;
				if (FI_WDATA_EN) begin
					if (inj_force && inj_type == INJ_WDATA) begin
						lcl_wdata = (s_wdata ^ flipper);
					end else begin
						lcl_wdata = s_wdata;
					end
				end
			end
		end
		ST_SEND: begin
			w_nxt = ST_SEND;

			if (FI_WDATA_EN) m_wdata = lcl_wdata;
			else 			 m_wdata = s_wdata;
			m_wstrb 	= s_wstrb;
			m_wlast		= s_wlast;
			m_wvalid	= s_wvalid;

			if (m_wready) begin
				s_wready = m_wready;
				w_nxt = ST_IDLE;
			end
		end
	endcase
end

//Write Response Channel
always @(*) begin
	s_bid 		= 0;
	s_bresp 	= 0;
	s_bvalid 	= 0;
	m_bready 	= 0;

	case (b_st)
		ST_IDLE: begin
			b_nxt = ST_IDLE;
			if (m_bvalid) b_nxt = ST_SEND;
		end
		ST_SEND: begin
			b_nxt = ST_SEND;

			s_bid 		= m_bid;
			s_bresp 	= m_bresp;
			s_bvalid 	= m_bvalid;

			if (s_bready) begin
				m_bready = s_bready;
				b_nxt = ST_IDLE;
			end
		end
	endcase
end

//Read Request Channel
always @(*) begin
	m_arid 		= 0;
	m_araddr	= 0;
	m_arlen		= 0;
	m_arsize	= 0;
	m_arburst	= 0;
	m_arvalid	= 0;
	s_arready	= 0;

	case (ar_st)
		ST_IDLE: begin
			ar_nxt = ST_IDLE;
			if (s_arvalid) begin
				ar_nxt = ST_SEND;
				if (FI_RADDR_EN) begin
					if (inj_force && inj_type == INJ_RADDR) begin
						lcl_araddr = (s_araddr ^ flipper);
					end else begin
						lcl_araddr = s_araddr;
					end // */
				end
			end
		end
		ST_SEND: begin
			ar_nxt = ST_SEND;

			m_arid 		= s_arid;
			if (FI_RADDR_EN) m_araddr = lcl_araddr;
			else 			 m_araddr = s_araddr;
			m_arlen		= s_arlen;
			m_arsize	= s_arsize;
			m_arburst	= s_arburst;
			m_arvalid	= s_arvalid;

			if (m_arready) begin
				s_arready = m_arready;
				ar_nxt = ST_IDLE;
			end
		end
	endcase
end

//Read Data Channel
always @(*) begin
	s_rid 		= 0;
	s_rdata 	= 0;
	s_rresp 	= 0;
	s_rlast 	= 0;
	s_rvalid 	= 0;
	m_rready 	= 0;

	case (r_st)
		ST_IDLE: begin
			r_nxt = ST_IDLE;
			if (m_rvalid) begin
				r_nxt = ST_SEND;
				if (FI_RDATA_EN) begin
					if (inj_force && inj_type == INJ_RDATA) begin
						lcl_rdata = (m_rdata ^ flipper);
					end else begin
						lcl_rdata = m_rdata;
					end
				end
			end
		end
		ST_SEND: begin
			r_nxt = ST_SEND;

			s_rid 		= m_rid;
			if (FI_RDATA_EN) 	s_rdata = lcl_rdata;
			else 				s_rdata = m_rdata;
			s_rresp 	= m_rresp;
			s_rlast 	= m_rlast;
			s_rvalid 	= m_rvalid;

			if (s_rready) begin
				m_rready = s_rready;
				r_nxt = ST_IDLE;
			end
		end
	endcase
end

endmodule
