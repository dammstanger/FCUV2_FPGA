/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：HC_SR04
工程描述：HC_SR04
作	 者：dammstanger
日	 期：20160820
*************************************************************************/	
module HC_SR04 (
input CLK,
input RSTn,

input  RXD1,
output TXD1,
input  RXD2,
output TXD2,

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


reg En_SR04;

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
		En_SR04 <= 1'b0;
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
		if(dy_timup)En_SR04 <= 1'b1;
	endcase



wire Dat_Rdy_Sig;
wire [15:0]Dist_mm;
HC_SR04_Driver #(16'd100) HC_SR04_Driver_U1(			//测量周期=100ms
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_SR04 ),
	.TRIG( TXD1 ),
	.ECHO( RXD1 ),
	.Dist_mm(Dist_mm),
	.Dat_Rdy_Sig( Dat_Rdy_Sig ),
	.STA(STA)
);

	
UART_datapkg_module UART_datapkg_module_SR04(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.TX_pin(TXD2),
	.RX_pin(RXD2),
	.Dist_mm(Dist_mm),
	.Dat_Rdy( Dat_Rdy_Sig )
);
assign SDRAM_A = Dist_mm[7:0];

endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
