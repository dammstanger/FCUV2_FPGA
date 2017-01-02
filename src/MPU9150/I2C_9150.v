/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：I2C_9150
工程描述：9150的驱动
作	 者：dammstanger
日	 期：20160815
*************************************************************************/	
module I2C_9150 (
input CLK,
input RSTn,

input  RXD2,
output TXD2,
output SCL2,
inout  SDA2,
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


reg En_9150;
//*****************PLL***************************
wire CLK_200M;
wire PLL_Lock_Sig;
PLL	PLL_inst (
	.inclk0 ( CLK ),
	.c0 ( CLK_200M ),
	.locked ( PLL_Lock_Sig )
	);


//***************延时**************************
reg En_delay;
wire dy_timup;

delayNms_module delayNms_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_delay),
	.Nms(16'd2000),
	.timeup(dy_timup)
);


wire Rx_FIFO_RD_Req;
wire [4:0]Rx_Dat_Cnt;
wire [7:0]Rx_Dat;


reg [1:0]sta;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		En_delay <= 1'b0;
		En_9150 <= 1'b0;
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
		if(dy_timup)En_9150 <= 1'b1;
	endcase



wire Dat_Rdy_Sig;
MPU9150_Driver MPU9150_Driver_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.CLK_SPI( CLK_200M ),
	.PLL_Locked( PLL_Lock_Sig ),
	.En( En_9150 ),
	.SCL( SCL2 ),
	.SDA( SDA2 ),
	.Rx_FIFO_RD_Req( Rx_FIFO_RD_Req ),
	.Rx_Dat_Cnt( Rx_Dat_Cnt ),
	.Rx_FIFO_dat( Rx_Dat ),
	.Dat_Rdy_Sig( Dat_Rdy_Sig ),
	.STA(STA)
);

	
UART_datapkg_module UART_datapkg_module_U2(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.TX_pin(TXD2),
	.RX_pin(RXD2),
	.Rx_FIFO_RD_Dat(Rx_Dat),
	.Dat_Num(Rx_Dat_Cnt),
	.Rx_RD_Req_sig(Rx_FIFO_RD_Req),
	.Dat_Rdy( Dat_Rdy_Sig )
);
assign SDRAM_A = Rx_Dat;
endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
