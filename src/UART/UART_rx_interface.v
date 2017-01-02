/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：UART_rx_interface
//工程描述：具有FIFO的串口接收接口
//作	 者：dammstanger
//日	 期：20160427
/*************************************************************************/	
module UART_rx_interface (CLK,RSTn,RD_Req_sig,BaudRate,FIFO_RD_Dat,Empty_sig,RX_pin,FrameCheck);
input CLK;
input RSTn;
input RD_Req_sig;
input [19:0]BaudRate;
input [1:0]FrameCheck;
output [7:0]FIFO_RD_Dat;
output Empty_sig;
input RX_pin;

	wire RxDoneflg;

	wire RxEn;

	wire [7:0]Revdat;
	
	UART_rx_module myUART_rx_module_1(
		.CLK(CLK),
		.RSTn(RSTn),		
		.Baudrate(BaudRate),
		.Revdat(Revdat),
		.RxDoneflg(RxDoneflg),
		.RxEn(RxEn),
		.RX_pin(RX_pin),
		.FrameCheck(FrameCheck)
		);
	
	wire WR_Req_sig;
	wire Full_sig;
	UART_fifo_rx_mgr myUART_fifo_rx_mgr_1(
		.CLK(CLK),
		.RSTn(RSTn),
		
		.RxDoneflg(RxDoneflg),
		.RxEn(RxEn),
		
		.Full_sig(Full_sig),
		.WR_Req_sig(WR_Req_sig)
	);
		
	
	fifo_module	fifo_module_rx_2 (
	.clock ( CLK ),
	.data ( Revdat ),
	.rdreq ( RD_Req_sig ),
	.wrreq ( WR_Req_sig ),
	.empty ( Empty_sig ),
	.full ( Full_sig ),
	.q ( FIFO_RD_Dat )
	);
	
endmodule




