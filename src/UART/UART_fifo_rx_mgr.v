/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：UART_fifo_rx_mgr
//工程描述：具有FIFO的串口收发程序测试
//作	 者：dammstanger
//日	 期：20160405
/*************************************************************************/			
module UART_fifo_rx_mgr (CLK,RSTn,RxDoneflg,RxEn,Full_sig,WR_Req_sig);
	input CLK;
	input RSTn;
	
	input Full_sig;

//	input[7:0]FIFO_WR_Dat;
	output WR_Req_sig;
	
	input RxDoneflg;
//	input [7:0]Rx_Dat;
	output RxEn;

	reg [1:0]sta;
	reg wrpulse;
	reg rRxEn;
	
always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
		begin
			sta <= 2'd0;
			wrpulse <= 1'b0;
			rRxEn <= 1'b0;
		end
	else if(!Full_sig)
		case (sta)
			2'd0:
				begin
				rRxEn <= 1'b1;
				if(RxDoneflg)
					sta <= 2'd1;
				end
			2'd1:
				begin 
				wrpulse <= 1'b1;
				sta <= 2'd2;
				end
			2'd2:
				begin 
				wrpulse <= 1'b0;
				sta <= 2'd0;
				end
		endcase		
	else 
		begin
		sta <= 2'd0;
		rRxEn <= 1'b0;
		end

assign WR_Req_sig = wrpulse;
assign RxEn = rRxEn;

endmodule




