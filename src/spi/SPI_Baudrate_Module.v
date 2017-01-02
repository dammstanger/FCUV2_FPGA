/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：SPI_Baudrate_Module
//工程描述：波特率发生器CLK=50MHz,最大速率25Mbps
//				Baudrate_Scaler分频器（1-32）：=1为1分频即CLK/2=25M，输出原时钟频率，=32 最大32分频，即CLK/(2^32)
//作	 者：dammstanger
//日	 期：20160804
/*************************************************************************/	
module SPI_Baudrate_Module (CLK, RSTn, En,Baudclk);
	input CLK;
	input RSTn;
	input En;
	output Baudclk;
	/********************************************/
	parameter SCALER=8'b1,CLK_FREE_LEVEL = 1'b0;
	reg	[31:0]rcnt;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
	begin
		if(CLK_FREE_LEVEL)
		rcnt <= 32'b1<<SCALER;
		else
		rcnt <= 32'b0;
	end
	else if(En)
		rcnt <= rcnt + 1'b1;
	else if(CLK_FREE_LEVEL)
		rcnt <= 32'b1<<(SCALER-1);
	else 
		rcnt <= 1'b0;
/***********************************/
 assign Baudclk = rcnt[SCALER-1'b1];

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
