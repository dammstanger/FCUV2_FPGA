/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//ģ�����ƣ�UART_tx_baudrate_module
//���������������ʷ�����CLK=50MHz
//��	 �ߣ�dammstanger
//��	 �ڣ�20160426
/*************************************************************************/	
`define FRECLK	28'd50_000_000			//28bit
`define BAUDRATE 20'd115200
`define NONE_CHECK	2'd0
`define ODD_CHECK	2'd1					//��У��
`define EVEN_CHECK	2'd2				//żУ��
module UART_tx_baudrate_module (CLK, RSTn, En,Baudrate,Baudclk);
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
	else if(En)
		if(rcnt==bcnt-1)
			rcnt <= 20'b0;
		else
			rcnt <= rcnt + 20'b1;
	else
		rcnt <= 20'b0;
		
/***********************************/
 assign Baudclk = (En&&rcnt==bcnt-1)? 1'b1 : 1'b0;

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
