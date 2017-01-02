/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//ģ�����ƣ�SPI_Baudrate_Module
//���������������ʷ�����CLK=50MHz,�������25Mbps
//				Baudrate_Scaler��Ƶ����1-32����=1Ϊ1��Ƶ��CLK/2=25M�����ԭʱ��Ƶ�ʣ�=32 ���32��Ƶ����CLK/(2^32)
//��	 �ߣ�dammstanger
//��	 �ڣ�20160811
/*************************************************************************/	
module SPI_Baudrate_Module (CLK, RSTn, En,Baudclk);
	input CLK;
	input RSTn;
	input En;
	output Baudclk;
	/********************************************/
	parameter SCALER=8'b1,CLK_FREE_LEVEL = 1'b0;			//SCALER ��Ƶϵ����CLK_FREE_LEVEL����ʱ�ӵĵ�ƽ
	reg	[31:0]rcnt;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )
	begin
		if(CLK_FREE_LEVEL)
		rcnt <= 32'b1<<(SCALER-1);
		else
		rcnt <= 32'b0;
	end
	else if(En)
		rcnt <= rcnt + 1'b1;
	else if(CLK_FREE_LEVEL)																//����ʱ��Ϊ�ߵ����
		rcnt <= 32'b1<<(SCALER-1);
	else 
		rcnt <= 1'b0;
/***********************************/
 assign Baudclk = rcnt[SCALER-1'b1];

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
