/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：ADNS_3080
//工程描述：读写3080
//作	 者：dammstanger
//日	 期：20160810
/*************************************************************************/	
module ADNS_3080 (
input CLK,
input RSTn,

input  RXD2,
output TXD2,
input  SPI1_MISO,
output SPI1_CLK,
output SPI1_MOSI,
output ADNS_CSN,
output ADNS_RST,

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
reg En_3080;

wire Rx_FIFO_RD_Req;
wire [2:0]Rx_Dat_Cnt;
wire [7:0]Rx_Dat;

wire [7:0]SBUF_SPI;
wire [7:0]RBUF_SPI;
wire SPI_RxDat_Rdy;
wire En_SPI;
wire SPI_Busy_Flg;
wire SPI_Rdy;



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
		En_3080 <= 1'b0;
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
		if(dy_timup)En_3080 <= 1'b1;
	endcase


adns3080_Driver adns3080_Driver_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_3080&SPI_Rdy),							//需要外部的使能和底层的SPI模块就绪 二者共同作用
	.En_SPI(En_SPI),
	.CSN(ADNS_CSN),
	.RST(ADNS_RST),
	.SBUF(SBUF_SPI),
	.RBUF(RBUF_SPI),
	.Rx_FIFO_RD_Req(Rx_FIFO_RD_Req),
	.Rx_FIFO_dat(Rx_Dat),
	.SPI_Busy_Flg(SPI_Busy_Flg),
	.SPI_RxDat_Rdy(SPI_RxDat_Rdy),
	.Rx_Dat_Cnt(Rx_Dat_Cnt),
//	.dat_out(SDRAM_A),
	.sta_out(STA)
);


SPI_module #(1'b1,1'b1,8'd5)SPI_module_U1(		//主模式，CLK空闲为高，5分频 1.56MHz
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_SPI),
	.PIN_MISO( SPI1_MISO ),
	.PIN_CLK(SPI1_CLK),
	.PIN_MOSI(SPI1_MOSI),	
	.SBUF(SBUF_SPI),
	.RBUF(RBUF_SPI),
	.Dat_Rdy_Sig(SPI_RxDat_Rdy),
	.Busy_Flg(SPI_Busy_Flg),
	.SPI_Rdy(SPI_Rdy)
);

//
//reg [3:0]sta2;
//always @ ( posedge CLK or negedge RSTn )
//	if( !RSTn )begin
//		Rx_FIFO_RD_Req <= 1'b0;
//		sta2 <= 1'b0;
//	end
//	else 
//	case(sta2)
//	4'b0:begin
//		if(Rx_Dat_Cnt==7)
//			sta2 <= sta2 +1'b1;
//	end
//	4'b1:begin
//		if(Rx_Dat_Cnt==0)
//			sta2 <= 1'b0;
//		else begin
//			Rx_FIFO_RD_Req <= 1'b1;
//			sta2 <= sta2 +1'b1;
//		end
//	end
//	4'd2:begin
//		Rx_FIFO_RD_Req <= 1'b0;
//		sta2 <= 4'b1;
//	end
//	endcase

//wire vclk;
//delayNms_cyc_module #(16'd200)delayNms_cyc_module_U2(
//	.CLK( CLK ),
//	.RSTn( RSTn ),
//	.vclk(vclk)
//);
	
UART_datapkg_module UART_datapkg_module_U2(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.TX_pin(TXD2),
	.RX_pin(RXD2),
	.Rx_FIFO_RD_Dat(Rx_Dat),
	.Dat_Num(Rx_Dat_Cnt),
	.Rx_RD_Req_sig(Rx_FIFO_RD_Req)
);

assign SDRAM_A = Rx_Dat;
endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
