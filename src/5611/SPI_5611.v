/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：SPI_5611
//工程描述：读写5611
//作	 者：dammstanger
//日	 期：20160819
/*************************************************************************/	
module SPI_5611 (
input CLK,
input RSTn,

input  RXD2,
output TXD2,
input  SPI3_MISO,
output SPI3_CLK,
output SPI3_MOSI,
output BARO_CSN,

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

reg En_delay;
wire dy_timup;
reg En_5611;

wire Rx_FIFO_Full;
wire Rx_FIFO_RD_Req;
wire [3:0]Rx_Dat_Cnt;
wire [7:0]Rx_Dat;

wire [7:0]SBUF_SPI;
wire [7:0]RBUF_SPI;
wire SPI_RxDat_Rdy;
wire En_SPI;
wire SPI_Busy_Flg;
wire SPI_Rdy;

wire FIFO_Dat_Rdy_Sig;

delayNms_module delayNms_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_delay),
	.Nms(16'd2000),
	.timeup(dy_timup)
);

reg [1:0]sta;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		En_delay <= 1'b0;
		En_5611 <= 1'b0;
		sta <= 1'b0;
	end
	else 
	case(sta)
	2'b0:begin
		En_delay <= 1'b1;
		sta <= sta +1'b1;
	end
	2'b1:begin
		En_delay <= 1'b0;
		sta <= sta +1'b1;
	end
	2'd2:
		if(dy_timup)En_5611 <= 1'b1;
	endcase


MS5611_Driver_SPI MS5611_Driver_SPI_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_5611&SPI_Rdy),							//需要外部的使能和底层的SPI模块就绪 二者共同作用
	.En_SPI(En_SPI),
	.CSN(BARO_CSN),
	.SBUF(SBUF_SPI),
	.RBUF(RBUF_SPI),
	.Rx_FIFO_RD_Req(Rx_FIFO_RD_Req),
	.Rx_FIFO_dat(Rx_Dat),
	.SPI_Busy_Flg(SPI_Busy_Flg),
	.SPI_RxDat_Rdy(SPI_RxDat_Rdy),
	.Dat_Rdy_Sig( FIFO_Dat_Rdy_Sig ),
	.Rx_Dat_Cnt(Rx_Dat_Cnt),
	.Rx_FIFO_Full(Rx_FIFO_Full),
	.sta_out(STA)
);

SPI_module #(1'b1,1'b0,8'd3)SPI_module_5611(		//主模式，CLK空闲为低，2分频 12.5MHz
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_SPI),
	.PIN_MISO( SPI3_MISO ),
	.PIN_CLK(SPI3_CLK),
	.PIN_MOSI(SPI3_MOSI),	
	.SBUF(SBUF_SPI),
	.RBUF(RBUF_SPI),
	.Dat_Rdy_Sig(SPI_RxDat_Rdy),
	.Busy_Flg(SPI_Busy_Flg),
	.SPI_Rdy(SPI_Rdy)
);


wire Calib_Rdy_Sig;
wire [31:0]Calib_Pressure;

MS5611_Calib_module MS5611_Calib_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Rx_FIFO_RD_Dat(Rx_Dat),
	.Dat_Num(Rx_Dat_Cnt),
	.Rx_FIFO_Full(Rx_FIFO_Full),
	.Rx_RD_Req_sig(Rx_FIFO_RD_Req),
	.Dat_Rdy( FIFO_Dat_Rdy_Sig ),
	.Calib_Rdy( Calib_Rdy_Sig ),
	.Calib_Pressure( Calib_Pressure )
);

	
UART_datapkg_module UART_datapkg_module_SR04(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.TX_pin(TXD2),
	.RX_pin(RXD2),
	.Data(Calib_Pressure),
	.Dat_Rdy( Calib_Rdy_Sig )
);

//UART_datapkg_module2 UART_datapkg_module_U2(
//	.CLK( CLK ),
//	.RSTn( RSTn ),
//	.TX_pin(TXD2),
//	.RX_pin(RXD2),
//	.Rx_FIFO_RD_Dat(Rx_Dat),
//	.Dat_Num(Rx_Dat_Cnt),
//	.Rx_FIFO_Full(Rx_FIFO_Full),
//	.Rx_RD_Req_sig(Rx_FIFO_RD_Req),
//	.Dat_Rdy( FIFO_Dat_Rdy_Sig )
//);

assign SDRAM_A = Calib_Pressure[7:0];
endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
