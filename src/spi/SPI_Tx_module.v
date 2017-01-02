/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：SPI_Tx_module
//工程描述：SPI发送模块
//作	 者：dammstanger
//日	 期：20160805
/*************************************************************************/	
module SPI_Tx_module 
(
    CLK, RSTn, MOSI, En, H2L_Sig, Busy_Sig, Data
);
   input CLK;
	 input RSTn;
	 output MOSI;
	 input En;
	 input H2L_Sig;
	 output Busy_Sig;
	 input [7:0]Data;
	 
	 /**********************************/
	 reg rBusy_Sig;
	 reg [3:0]sta;
	 reg rMOSI;
	 /**********************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta <= 1'b0;
		rBusy_Sig <= 1'b0;
		rMOSI <= 1'b0;
	end
	else begin
		case(sta)
		4'd0:begin
			if(En)begin										//脉冲触发型				
				rMOSI <= Data[7];
				sta <= sta +1'b1;
				rBusy_Sig <= 1'b1;
			end
		end
		4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7:begin
			if(H2L_Sig)begin
				rMOSI <= Data[7-sta];
				sta <= sta +1'b1;
			end
		end
		4'd8:begin
			if(H2L_Sig)begin
				rBusy_Sig <= 1'b0;
				sta <= 1'b0;
			end
		end
		endcase
	end
assign Busy_Sig = rBusy_Sig;		
assign MOSI = rMOSI;
	 
	 /***********************************/
	 
endmodule

