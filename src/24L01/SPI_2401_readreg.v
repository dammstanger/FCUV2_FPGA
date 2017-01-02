/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：SPI_2401_readreg
//工程描述：SPI测试，读写24L01寄存器
//作	 者：dammstanger
//日	 期：20160809
/*************************************************************************/	
module SPI_2401_readreg (
input CLK,
input RSTn,

input  SPI2_MISO,
output SPI2_CLK,
output SPI2_MOSI,
output NRF_CE,
output NRF_CSN,
input  NRF_IRQ,

output PWM_OUT1,
output PWM_OUT2,
output PWM_OUT3,
output PWM_OUT4,
output PWM_OUT5,
output PWM_OUT6,
output PWM_OUT7,
output PWM_OUT8,
output [7:0]SDRAM_A,
output [2:0]STA
);

parameter En_2401= 1'b1;
wire [7:0]SBUF_SPI;
wire [7:0]RBUF_SPI;
wire RD_Req_sig;
wire SPI_RxDat_Rdy;
wire En_SPI;
wire SPI_Busy_Flg;
wire SPI_Rdy;

SPI_2401_Driver SPI_2401_Driver_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_2401&SPI_Rdy),							//需要外部的使能和底层的SPI模块就绪 二者共同作用
	.En_SPI(En_SPI),
	.CE(NRF_CE),
	.CSN(NRF_CSN),
	.IRQ(NRF_IRQ),
	.SBUF(SBUF_SPI),
	.RBUF(RBUF_SPI),
	.Rx_FIFO_RD_Req(),
	.Tx_FIFO_WR_Req(),
	.Tx_FIFO_dat(),
	.Rx_FIFO_dat(),
	.Rx_FIFO_Full(),
	.Tx_FIFO_Empty(),
	.SPI_Busy_Flg(SPI_Busy_Flg),
	.SPI_RxDat_Rdy(SPI_RxDat_Rdy),
	.sta_out(STA)
);


SPI_module SPI_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_SPI),
	.PIN_MISO( SPI2_MISO ),
	.PIN_CLK(SPI2_CLK),
	.PIN_MOSI(SPI2_MOSI),
	.SBUF(SBUF_SPI),
	.RBUF(RBUF_SPI),
	.Dat_Rdy_Sig(SPI_RxDat_Rdy),
	.Busy_Flg(SPI_Busy_Flg),
	.SPI_Rdy(SPI_Rdy)
);

assign SDRAM_A = RBUF_SPI;

endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
