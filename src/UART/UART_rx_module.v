/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：UART_rx_module
//工程描述：UART 的接收模块
//作	 者：dammstanger
//日	 期：20160427
/*************************************************************************/	
module UART_rx_module (CLK,RSTn,RxEn,Baudrate,RX_pin,Revdat,RxDoneflg,FrameCheck);
input CLK;
input RSTn;
input RxEn;
input [19:0]Baudrate;
input RX_pin;
input [1:0]FrameCheck;
output [7:0]Revdat;
output RxDoneflg;
	/********************************************/
wire HtL_sig;

HtL_detect_module myHtL(
	.CLK(CLK),
	.RSTn(RSTn),
	.Pin_In(RX_pin),
	.H2L_Sig(HtL_sig)
);

wire Baudclk;
wire EnBuadcnt;

UART_baudrate_module mybaud(
	.CLK(CLK),
	.RSTn(RSTn),
	.En(EnBuadcnt),
	.Baudrate(Baudrate),
	.Baudclk(Baudclk)
);

UART_rx_ctl_module rx(
	.CLK(CLK),
	.RSTn(RSTn),
	.En(RxEn),
	.HtL_sig(HtL_sig),
	.RX_pin(RX_pin),
	.Baudclk(Baudclk),
	.Enbaud(EnBuadcnt),
	.SBUF(Revdat),
	.Doneflg(RxDoneflg),
	.FrameCheck(FrameCheck)
);





endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
