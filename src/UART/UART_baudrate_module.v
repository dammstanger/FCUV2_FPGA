/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：UART_baudrate_module
//工程描述：波特率发生器CLK=200MHz
//作	 者：dammstanger
//日	 期：20160426
/*************************************************************************/	
module UART_baudrate_module (CLK, RSTn, En,Baudrate,Baudclk);
	input CLK;
	input RSTn;
	input En;
	input [19:0]Baudrate;
	output Baudclk;
	/********************************************/

	wire [19:0]bcnt = `FRECLK/Baudrate;
	reg	[19:0]rcnt;
always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
		begin
			rcnt <= 20'd0;
		end
	else if(En&&rcnt<bcnt-1)
		rcnt <= rcnt + 20'b1;
	else
		rcnt <= 20'b0;
		
		
/***********************************/
 assign Baudclk = (rcnt==bcnt/2)? 1'b1 : 1'b0;

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
