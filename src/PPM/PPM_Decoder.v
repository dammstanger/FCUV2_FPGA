/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：PPM_Decoder
工程描述: PPM信号解码器8CH 
作	 者：dammstanger
日	 期：20160820
*************************************************************************/	
`define CHANNEL_8
`ifdef CHANNEL_8
`define CHANNEL		4'd8
`else
`define CHANNEL		4'd6
`endif
`define DAT_WIDTH	`CHANNEL*11-1
module PPM_Decoder (
input CLK,
input RSTn,
input  En,
input Sig_In,
output Dat_Rdy_Sig,
output [`DAT_WIDTH:0]Dat_CH
);


//***********************************************
reg En_cnt;
wire OverFlow;
wire [15:0]Time_us;
Time_us_16b Time_us_16b_PPM( 
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_cnt ), 
	.Nus( Time_us ), 
	.OVERFLW( OverFlow )
);


//******************信号边缘检测****************
wire H2L_Sig;
wire L2H_Sig;
wire Edge_Detect_Rdy;
Sig_Edge_Detect Sig_Edge_Detect_TRIG(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Edge_Detect_Rdy),
	.Pin_In(Sig_In), 									
	.H2L_Sig(H2L_Sig), 
	.L2H_Sig(L2H_Sig)	
);


	
/****************总状态机********************/
	 parameter 	IDLE = 2'd0,
							CAPT = 2'd1,
							DEAL = 2'd2;
	
	reg [2:0]sta;
	reg [4:0]substp;
	reg [2:0]Ch_num;
	reg rDat_Rdy;
	reg [`DAT_WIDTH:0]rDat_CH;
	reg [15:0]rTime_us;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		rDat_CH <= 1'b0;
		En_cnt <= 1'b0;
		sta <= IDLE;
		substp <= 1'b0;
		rTime_us<= 1'b0;
		rDat_Rdy <= 1'b0;
	end
	else begin
		if(En&Edge_Detect_Rdy)
			case(sta)
			IDLE:begin
				rDat_Rdy <= 1'b0;
				if(Sig_In)		//如果开始为高电平进入测量
					sta <= CAPT;
				else
					sta <= IDLE;			
			end
			CAPT:
				case(substp)
				5'd0://----------------------------------------------------
					if(L2H_Sig)begin
						En_cnt <= 1'b1;
						substp <= substp + 1'b1;
					end
					else
						substp <= 5'b0;
				5'd1:
					if(H2L_Sig)begin
						En_cnt <= 1'b0;
						rTime_us <= Time_us;
						substp <= 1'b0;
						sta <= DEAL;
					end
					else if(OverFlow)begin
						En_cnt <= 1'b0;
						substp <= 1'b0;
						Ch_num <= 1'b0;
						rDat_CH <= 1'b0;
						sta <= IDLE;
					end
					else
						substp <= 5'd1;	
				endcase		
			DEAL:
				if(rTime_us>16'd500&&rTime_us<16'd2100)begin
					case(Ch_num)
						3'd0:  rDat_CH[10:0] <= rTime_us[10:0];
						3'd1:  rDat_CH[21:11] <= rTime_us[10:0];
						3'd2:  rDat_CH[32:22] <= rTime_us[10:0];
						3'd3:  rDat_CH[43:33] <= rTime_us[10:0];
						3'd4:  rDat_CH[54:44] <= rTime_us[10:0];
						3'd5:  rDat_CH[65:55] <= rTime_us[10:0];
						`ifdef CHANNEL_8
						3'd6:  rDat_CH[76:66] <= rTime_us[10:0];
						3'd7:  rDat_CH[87:77] <= rTime_us[10:0];
						`endif
					endcase
					if(Ch_num==`CHANNEL-1)begin
						Ch_num <= 1'b0;
						rDat_Rdy <= 1'b1;
						sta <= IDLE;
					end
					else begin
						Ch_num <= Ch_num + 1'b1;
						sta <= CAPT;
					end
				end
				else begin
					Ch_num <= 1'b0;
					sta <= IDLE;
				end
				default:sta <= IDLE;
			endcase
		else begin
			rDat_CH <= 1'b0;
		end
	end

assign Dat_CH = rDat_CH;
assign Dat_Rdy_Sig = rDat_Rdy;

endmodule



/**********************END OF FILE COPYRIGHT @2016************************/	
