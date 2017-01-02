/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：Top_module
工程描述：模拟SRAM以及FSMC接口，与STM32对接，使STM32直接读取FPGA寄存器，
注	 意： 32位分两次读出：低位在地址值，先被读出。如果只取低16位，则只读一次，
					arm程序只取高16位也会读两次取出完整的32位。
作	 者：dammstanger
日	 期：20160902
*************************************************************************/	
module Top_module (
input CLK,
input RSTn,
//UART1 2
input  RXD1,
output TXD1,
input  RXD2,
output TXD2,

//FSMC
input SDRAM_NE1,
input SDRAM_NWE,
input SDRAM_NOE,
input [1:0]SDRAM_NBL,
inout [15:0]SDRAM_DB,
input [15:0]SDRAM_A,
//SIP2401
input  SPI2_MISO,
output SPI2_CLK,
output SPI2_MOSI,
output NRF_CE,
output NRF_CSN,
input  NRF_IRQ,
//SIP3080
input  SPI1_MISO,
output SPI1_CLK,
output SPI1_MOSI,
output ADNS_CSN,
output ADNS_RST,
//MPU9150
output SCL2,
inout  SDA2,
//MS5611
input  SPI3_MISO,
output SPI3_CLK,
output SPI3_MOSI,
output BARO_CSN,
////PWM
output PWM_OUT1,
output PWM_OUT2,
output PWM_OUT3,
output PWM_OUT4,
output PWM_OUT5,
output PWM_OUT6,
output PWM_OUT7,
output PWM_OUT8,
//PPM
input PPM_IN,
//INT
output INT1,
output CLK_Out
//output [2:0]sta_dbg,
//output [3:0]sta_stp
);

//=========================200M 200M PLL================================
//50MHz的外部晶振下，EP4CE22F17C8的核最高频率允许：472 MHz
wire CLK_200M;
wire PLL_Lock;
PLL	PLL200_U1 (
	.areset ( ~RSTn ),					//PLL异步复位信号,高有效
	.inclk0 ( CLK ),
	.c0 ( CLK_200M ),
	.locked ( PLL_Lock )
	);

assign CLK_Out = CLK_200M;
reg En_sys;

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



reg [1:0]sta;
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		En_delay <= 1'b0;
		En_sys <= 1'b0;
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
		if(dy_timup)En_sys <= 1'b1;
	endcase
	

//==========================ADNS3080=================================

wire Rx_FIFO_RD_3080;
wire [2:0]Rx_Dat_Cnt_3080;
wire [7:0]Rx_Dat_3080;
wire Time_Mark_3080;

wire [7:0]SBUF_SPI1;
wire [7:0]RBUF_SPI1;
wire SPI1_RxDat_Rdy;
wire En_SPI1;
wire SPI1_Busy_Flg;
wire SPI1_Rdy;

adns3080_Driver adns3080_Driver_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_sys&SPI1_Rdy),							//需要外部的使能和底层的SPI模块就绪 二者共同作用
	.En_SPI(En_SPI1),
	.CSN(ADNS_CSN),
	.RST(ADNS_RST),
	.SBUF(SBUF_SPI1),
	.RBUF(RBUF_SPI1),
	.Rx_FIFO_RD_Req(Rx_FIFO_RD_3080),
	.Rx_FIFO_dat(Rx_Dat_3080),
	.SPI_Busy_Flg(SPI1_Busy_Flg),
	.SPI_RxDat_Rdy(SPI1_RxDat_Rdy),
	.Rx_Dat_Cnt(Rx_Dat_Cnt_3080),
	.Time_Mark( Time_Mark_3080 )
);


SPI_module #(1'b1,1'b1,8'd5)SPI_module_3080(		//主模式，CLK空闲为高，5分频 1.56MHz
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_SPI1),
	.PIN_MISO( SPI1_MISO ),
	.PIN_CLK(SPI1_CLK),
	.PIN_MOSI(SPI1_MOSI),	
	.SBUF(SBUF_SPI1),
	.RBUF(RBUF_SPI1),
	.Dat_Rdy_Sig(SPI1_RxDat_Rdy),
	.Busy_Flg(SPI1_Busy_Flg),
	.SPI_Rdy(SPI1_Rdy)
);

//==================MPU9150=================================
wire Time_Mark_9150;
wire Dat_Rdy_9150;
wire Rx_RD_Req_9150;
wire [4:0]Rx_Dat_Cnt_9150;
wire [7:0]Rx_Dat_9150;
MPU9150_Driver MPU9150_Driver_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.CLK_SPI( CLK_200M ),
	.PLL_Locked( PLL_Lock ),
	.En( En_sys ),
	.SCL( SCL2 ),
	.SDA( SDA2 ),
	.Rx_FIFO_RD_Req( Rx_RD_Req_9150 ),
	.Rx_Dat_Cnt( Rx_Dat_Cnt_9150 ),
	.Rx_FIFO_dat( Rx_Dat_9150 ),
	.Dat_Rdy_Sig( Dat_Rdy_9150 ),
	.Time_Mark(Time_Mark_9150)
);

//================MS5611===================================
wire Rx_FIFO_Full_5611;					  //用于校准用的数据就绪
wire Rx_FIFO_RD_Req_5611;
wire [3:0]Rx_Dat_Cnt_5611;
wire [7:0]Rx_Dat_5611;
wire Time_Mark_5611;

wire [7:0]SBUF_SPI3;
wire [7:0]RBUF_SPI3;
wire SPI3_RxDat_Rdy;
wire En_SPI3;
wire SPI3_Busy_Flg;
wire SPI3_Rdy;

wire FIFO_Dat_Rdy_5611;						//用于提示PROM和温度压力数据就绪

MS5611_Driver_SPI MS5611_Driver_SPI3_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_sys&SPI3_Rdy),							//需要外部的使能和底层的SPI模块就绪 二者共同作用
	.En_SPI(En_SPI3),
	.CSN(BARO_CSN),
	.SBUF(SBUF_SPI3),
	.RBUF(RBUF_SPI3),
	.Rx_FIFO_RD_Req(Rx_FIFO_RD_Req_5611),
	.Rx_FIFO_dat(Rx_Dat_5611),
	.Rx_Dat_Cnt(Rx_Dat_Cnt_5611),
	.Rx_FIFO_Full(Rx_FIFO_Full_5611),
	.SPI_Busy_Flg(SPI3_Busy_Flg),
	.SPI_RxDat_Rdy(SPI3_RxDat_Rdy),
	.Dat_Rdy_Sig( FIFO_Dat_Rdy_5611 ),
	.Time_Mark( Time_Mark_5611 )
);

SPI_module #(1'b1,1'b0,8'd3)SPI3_module_5611(		//主模式，CLK空闲为低，3分频 6.25MHz
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_SPI3),
	.PIN_MISO( SPI3_MISO ),
	.PIN_CLK(SPI3_CLK),
	.PIN_MOSI(SPI3_MOSI),	
	.SBUF(SBUF_SPI3),
	.RBUF(RBUF_SPI3),
	.Dat_Rdy_Sig(SPI3_RxDat_Rdy),
	.Busy_Flg(SPI3_Busy_Flg),
	.SPI_Rdy(SPI3_Rdy)
);



wire Calib_Rdy_5611;
wire [31:0]Calib_Pressure;

MS5611_Calib_module MS5611_Calib_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Rx_FIFO_RD_Dat(Rx_Dat_5611),
	.Dat_Num(Rx_Dat_Cnt_5611),
	.Rx_FIFO_Full(Rx_FIFO_Full_5611),
	.Rx_RD_Req_sig(Rx_FIFO_RD_Req_5611),
	.Dat_Rdy( FIFO_Dat_Rdy_5611 ),
	.Calib_Rdy( Calib_Rdy_5611 ),
	.Calib_Pressure( Calib_Pressure )
);

	
//UART_datapkg_module UART_datapkg_module_5611(
//	.CLK( CLK ),
//	.RSTn( RSTn ),
//	.TX_pin(TXD2),
//	.RX_pin(RXD2),
//	.Data(Calib_Pressure),
//	.Dat_Rdy( Calib_Rdy_5611 )
//);

//=================SR04============================
wire Dat_Rdy_SR04;
wire Time_Mark_SR04;
wire [15:0]Dist_mm;
HC_SR04_Driver #(16'd100) HC_SR04_Driver_U1(			//测量周期=100ms
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_sys ),
	.TRIG( TXD1 ),
	.ECHO( RXD1 ),
	.Dist_mm(Dist_mm),
	.Dat_Rdy_Sig( Dat_Rdy_SR04 ),
	.Time_Mark(Time_Mark_SR04)
);

//	
//UART_datapkg_module UART_datapkg_module_SR04(
//	.CLK( CLK ),
//	.RSTn( RSTn ),
//	.TX_pin(TXD2),
//	.RX_pin(RXD2),
//	.Dist_mm(Dist_mm),
//	.Dat_Rdy( Dat_Rdy_SR04 )
//);


	
//****************全局计时器*******************************
wire Timer_Top_OverFlow;
wire [63:0]Time_us;
Time_us_64b Time_us_63b_Top( 
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_sys ), 
	.Nus( Time_us )		//溢出可能极小
);


//===============Data Schedule=============================
wire DatRdy_3080;
wire [1:0]DatRdy_9150;			//bit1 mag rdy  bit0 imu rdy
wire DatRdy_5611;
wire DatRdy_SR04;
wire [119:0]ADNS3080_Dat;
wire [223:0]MPU9150_Dat;
wire [95:0]MS5611_Dat;
wire [79:0]SR04_Dat;

Data_Schedule_module Data_Schedule_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_sys),	
	
	.Time_us( Time_us ),
	
	.Dat_3080( Rx_Dat_3080 ),
	.Dat_Num_3080( Rx_Dat_Cnt_3080 ),
	.RD_Req_3080( Rx_FIFO_RD_3080 ),
	.DatRdy_3080( DatRdy_3080 ),
	.ADNS3080_Dat( ADNS3080_Dat ),
	.Time_Mark_3080( Time_Mark_3080 ),
	//--
	.Dat_9150( Rx_Dat_9150 ),
	.Dat_Num_9150( Rx_Dat_Cnt_9150 ),
	.Dat_Rdy_In_9150( Dat_Rdy_9150 ),
	.RD_Req_9150( Rx_RD_Req_9150 ),
	.DatRdy_9150( DatRdy_9150 ),
	.MPU9150_Dat( MPU9150_Dat ),
	.Time_Mark_9150( Time_Mark_9150 ),
	//--
	.Dat_5611( Calib_Pressure ),
	.Dat_Rdy_In_5611( Calib_Rdy_5611 ),
	.DatRdy_5611( DatRdy_5611 ),
	.MS5611_Dat( MS5611_Dat ),
	.Time_Mark_5611( Time_Mark_5611 ),
	//--
	.Dat_SR04( Dist_mm ),
	.Dat_Rdy_In_SR04( Dat_Rdy_SR04 ),
	.DatRdy_SR04( DatRdy_SR04 ),
	.SR04_Dat( SR04_Dat ),
	.Time_Mark_SR04( Time_Mark_SR04 )
	
);
//========================FSMC====================================
wire [15:0]ARM_Cmd;
wire [127:0]PWM_Out;
FSMC_module FSMC_module_U1(
	.CLK( CLK_200M ),
	.RSTn( RSTn ),
	.En( En_sys ),
	
	.MPU_Rdy( DatRdy_9150 ),
	.ADNS3080_Rdy( DatRdy_3080 ),
	.AirPress_Rdy( DatRdy_5611 ),
	.Ultra_Rdy( DatRdy_SR04 ),
	.ADNS3080_Dat( ADNS3080_Dat ),		//7个字节
	.MPU_Dat( MPU9150_Dat ),					//10个16bit字
	.AirPress_Dat( MS5611_Dat ),			//1个32位字
	.Ultra_Dat( SR04_Dat ),						//1个16位字
	
.INT( INT1 ),
.Cmd( ARM_Cmd ),
.PWM_Out( PWM_Out ),
.NE1( SDRAM_NE1 ),
.NWE( SDRAM_NWE ),
.NOE( SDRAM_NOE ),
.DAT( SDRAM_DB ),
.ADDR( SDRAM_A )	
);

//=======================RFdebug=================================
RFdebug_module RFdebug_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_sys ),
	
	.ADNS3080_Rdy( DatRdy_3080 ),
	.MPU_Rdy( DatRdy_9150[1] ),		//bit1 mag rdy 刷新频率不需要太高
	.AriPress_Rdy( DatRdy_5611 ),
	.Ultra_Rdy( DatRdy_SR04 ),
	.ADNS3080_Dat( ADNS3080_Dat ),		//7个字节
	.MPU_Dat( MPU9150_Dat ),					//10个16bit字
	.AriPress_Dat( MS5611_Dat ),			//1个32位字
	.Ultra_Dat( Dist_mm ),						//1个16位字
	
	.NRF_CE( NRF_CE),
	.NRF_CSN( NRF_CSN),
	.NRF_IRQ( NRF_IRQ),
	.SPI2_MISO( SPI2_MISO ),
	.SPI2_CLK(SPI2_CLK),
	.SPI2_MOSI(SPI2_MOSI)
);

//===========================PPM==================================
wire [87:0]PPM_Dat;
wire Dat_Rdy_PPM;
PPM_Decoder PPM_Decoder_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_sys ),
	.Sig_In( PPM_IN ),
	.Dat_Rdy_Sig( Dat_Rdy_PPM ),
	.Dat_CH( PPM_Dat )
);

UART_datapkg_module UART_datapkg_module_PPM(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.TX_pin(TXD2),
	.RX_pin(RXD2),
	.Dat_In(PPM_Dat),
	.Dat_Rdy( Dat_Rdy_PPM )
);


//===========================PWM==================================	
PWM_Gener PWM_Gener_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_sys ),
	.Channel1( PWM_Out[15:0] ),
	.Channel2( PWM_Out[31:16] ),
	.Channel3( PWM_Out[47:32] ),
	.Channel4( PWM_Out[63:48] ),
	.Channel5( PWM_Out[79:64] ),
	.Channel6( PWM_Out[95:80] ),
	.Channel7( PWM_Out[111:96] ),
	.Channel8( PWM_Out[127:112] ),
	.Sig_Out1( PWM_OUT1 ),
	.Sig_Out2( PWM_OUT2 ),
	.Sig_Out3( PWM_OUT3 ),
	.Sig_Out4( PWM_OUT4 ),
	.Sig_Out5( PWM_OUT5 ),
	.Sig_Out6( PWM_OUT6 ),
	.Sig_Out7( PWM_OUT7 ),
	.Sig_Out8( PWM_OUT8 )
);
		
	

endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
