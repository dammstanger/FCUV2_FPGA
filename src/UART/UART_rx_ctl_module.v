/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：UART_rx_ctl_module
//工程描述：波特率发生器CLK=50MHz
//作	 者：dammstanger
//日	 期：20160426
/*************************************************************************/	

module UART_rx_ctl_module (CLK, RSTn, En,HtL_sig,RX_pin,Baudclk,FrameCheck,Enbaud,SBUF,Doneflg);
	input CLK;
	input RSTn;
	input En;
	input HtL_sig;
	input RX_pin;
	input Baudclk;
	input [1:0]FrameCheck;
	output Enbaud;
	output [7:0]SBUF;
	output Doneflg;
	/********************************************/
`define NONE_CHECK	2'd0
`define ODD_CHECK	2'd1					//奇校验
`define EVEN_CHECK	2'd2				//偶校验
	/********************************************/
	reg [3:0]sta;
	reg rEnbaud;
	reg [7:0]rSBUF;
	reg rDoneflg;
	reg add;
	reg err;
	
always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
		begin
			sta <= 4'd0;
			rEnbaud <= 1'b0;
			rSBUF <= 8'd0;
			rDoneflg <= 1'b0;
			add <= 1'b0;
			err <= 1'b0;
		end
	else 
		case(sta)
			4'd0:
			if(En)
				if(HtL_sig)
					begin
					sta <= 4'd1;
					rEnbaud <= 1'b1;
					end
			4'd1:
				if(Baudclk)
					begin
					sta <= 4'd2;
					end
			4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8,4'd9:
				if(Baudclk)
					begin
					sta <= sta +4'b1;
					rSBUF[sta-2] <= RX_pin;
					add <= add + RX_pin;
					end
			4'd10:
				if(Baudclk)
					begin
					case (FrameCheck)
						`NONE_CHECK:
							begin
							rDoneflg <= 1'b1;
							sta <= 4'd12;
							rEnbaud <=1'b0;
							end			
						`ODD_CHECK:
							begin
							if(add==RX_pin) err <= 1'b1;
							sta <= 4'd11;
							end
						`EVEN_CHECK:
							begin
							if(add!=RX_pin) err <= 1'b1;
							sta <= 4'd11;
							end
//					if(FrameCheck==`NONE_CHECK)
//						begin
//						rDoneflg <= 1'b1;
//						sta <= 4'd12;
//						rEnbaud <=1'b0;
//						end
//					else if(FrameCheck==`EVEN_CHECK)	//偶校验
//						if(add!=RX_pin) err <= 1'b1;
//					else if(FrameCheck==`ODD_CHECK)		//奇校验
//						if(add==RX_pin) err <= 1'b1;
					endcase
					end
			4'd11:
				if(Baudclk)
				begin
					if(err)
						err <= 1'b0;
					else
					rDoneflg <= 1'b1;
					sta <= 4'd12;
					rEnbaud <=1'b0;
				end
			4'd12:
				begin
					rDoneflg <= 1'b0;
					add <= 1'b0;
					sta <= 4'd0;
				end
			endcase
		
			
/***********************************/
	assign Enbaud = rEnbaud;
	assign Doneflg = rDoneflg;
	assign SBUF = rSBUF;
endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
