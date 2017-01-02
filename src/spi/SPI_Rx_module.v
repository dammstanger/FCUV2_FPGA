/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：SPI_Rx_module
//工程描述：接收模块
//作	 者：dammstanger
//日	 期：20160805
/*************************************************************************/	
module SPI_Rx_module 
(
    CLK, RSTn, MISO, En, L2H_Sig, Rdy_Sig, Data
);
   input CLK;
	 input RSTn;
	 input MISO;
	 input En;
	 input L2H_Sig;
	 output Rdy_Sig;
	 output [7:0]Data;
	 
	 /**********************************/
	 reg [7:0]rData;
	 reg rRdy_Sig;
	 reg [3:0]sta;
	 /**********************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta <= 4'd8;
		rData <= 1'b0;
		rRdy_Sig <= 1'b0;
	end
	else begin
		case(sta)
		4'd8:begin
			rRdy_Sig <= 1'b0;
			if(En)begin						//触发型
				sta <= 1'b0;
			end
		end
		4'd0,4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7:begin
			if(L2H_Sig)begin
				rData[7-sta] <= MISO;
				sta <= sta +1'b1;
				if(sta==4'd7)
					rRdy_Sig <= 1'b1;
			end
		end
		endcase
	end
assign Rdy_Sig = rRdy_Sig;		
//assign Data = rRdy_Sig? rData:8'b0;
assign Data = rData;
	 /***********************************/
	 
endmodule

