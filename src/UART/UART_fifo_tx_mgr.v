/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：UART_fifo_tx_mgr
//工程描述：具有FIFO的串口收发程序测试
//作	 者：dammstanger
//日	 期：20160405
/*************************************************************************/	
module UART_fifo_tx_mgr (CLK,RSTn,Empty_sig,RD_Req_sig,FIFO_RD_Dat,Tx_Dat,Tx_Done_sig,TxEn);
	input CLK;
	input RSTn;
	
	input Empty_sig;
	input [7:0]FIFO_RD_Dat;
	output RD_Req_sig;
	
	input Tx_Done_sig;
	output [7:0]Tx_Dat;
	output TxEn;

	reg [1:0]sta;
	reg Readpulse;
	reg rTxEn;
always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
		begin
			sta <= 2'd0;
			Readpulse <= 1'b0;
			rTxEn <= 1'b0;
		end
	else 
		case (sta)
			2'd0:
				if(!Empty_sig)
					sta <= 2'd1;
			2'd1:
				begin 
				Readpulse <= 1'b1;
				sta <= 2'd2;
				end
			2'd2:
				begin 
				Readpulse <= 1'b0;
				sta <= 2'd3;
				end
			2'd3:
				if(Tx_Done_sig)
					begin 
						rTxEn <= 1'b0;
						sta <= 2'd0;
					end
				else
					rTxEn <= 1'd1;
		endcase		

assign RD_Req_sig = Readpulse;
assign Tx_Dat = FIFO_RD_Dat;
assign TxEn = rTxEn;

endmodule




