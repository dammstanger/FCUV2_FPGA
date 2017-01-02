/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�������ƣ�UART_tx_module
//����������UART ���Ͳ���
//��	 �ߣ�dammstanger
//��	 �ڣ�20160426
/*************************************************************************/	
module UART_tx_module (CLK,RSTn,TxEn,BaudRate,FrameCheck,Senddat,TX_pin,Doneflg);
input CLK;
input RSTn;
input TxEn;
input [19:0]BaudRate;
input [1:0]FrameCheck;
input [7:0]Senddat;
output TX_pin;
output Doneflg;

	/********************************************/

wire Baudclk;
wire EnBuadcnt;

UART_tx_baudrate_module mybaud(
	.CLK(CLK),
	.RSTn(RSTn),
	.En(EnBuadcnt),
	.Baudrate(BaudRate),
	.Baudclk(Baudclk)
);

//------------------------------------------

UART_tx_ctl_module tx(
	.CLK(CLK),
	.RSTn(RSTn),
	.En(TxEn),
	.TX_pin(TX_pin),
	.Baudclk(Baudclk),
	.FrameCheck(FrameCheck),
	.Enbaud(EnBuadcnt),
	.SBUF(Senddat),
	.Doneflg(Doneflg)
);

endmodule


/**********************END OF FILE COPYRIGHT @2016************************/	
