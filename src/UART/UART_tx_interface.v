/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：UART_tx_interface
//工程描述：具有FIFO的串口收发程序测试
//作	 者：dammstanger
//日	 期：20160911
/*************************************************************************/	
module UART_tx_interface (CLK,RSTn,WR_Req_sig,BaudRate,FrameCheck,FIFO_WR_Dat,Full_sig,TX_pin);
input CLK;
input RSTn;
input WR_Req_sig;
input [19:0]BaudRate;
input [1:0]FrameCheck;
input [7:0]FIFO_WR_Dat;
output Full_sig;
output TX_pin;

wire [7:0]FIFO_RD_Dat;
wire RD_Req_sig;
wire Empty_sig;

FIFO_8_4	FIFO_UART (
	.clock ( CLK ),
	.data ( FIFO_WR_Dat ),
	.rdreq ( RD_Req_sig ),
	.wrreq ( WR_Req_sig ),
	.empty ( Empty_sig ),
	.full ( Full_sig ),
	.q ( FIFO_RD_Dat )
	);

	wire [7:0]Sendat;
	wire Sendoneflg;
	wire TxEn;
	
	UART_fifo_tx_mgr myUART_fifo_tx_mgr_1(
		.CLK(CLK),
		.RSTn(RSTn),
		.Empty_sig(Empty_sig),
		.RD_Req_sig(RD_Req_sig),
		.FIFO_RD_Dat(FIFO_RD_Dat),
		.Tx_Dat(Sendat),
		.Tx_Done_sig(Sendoneflg),
		.TxEn(TxEn)
	);
	
	UART_tx_module myUART_tx_module_1(
		.CLK(CLK),
		.RSTn(RSTn),		
		.BaudRate(BaudRate),
		.FrameCheck(FrameCheck),
		.Senddat(Sendat),
		.Doneflg(Sendoneflg),
		.TxEn(TxEn),
		.TX_pin(TX_pin)
		);
	

endmodule




