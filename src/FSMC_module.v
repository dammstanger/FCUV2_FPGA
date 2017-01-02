/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：FSMC_module
工程描述：模拟SRAM以及FSMC接口，与STM32对接，使STM32直接读取FPGA寄存器，
注	 意： 32位分两次读出：低位在低地址值，先被读出。如果只取低16位，则只读一次，
					arm程序只取高16位也会读两次取出完整的32位。
作	 者：dammstanger
日	 期：20160915
*************************************************************************/	
module FSMC_module (
input CLK,
input RSTn,
input En,
input [1:0]MPU_Rdy,
input ADNS3080_Rdy,
input AirPress_Rdy,
input Ultra_Rdy,
input [119:0]ADNS3080_Dat,		//7个字节
input [223:0]MPU_Dat,				//10个16bit字，
input [95:0]AirPress_Dat,		//1个32位字
input [79:0]Ultra_Dat,			//1个16位字
output INT,
output [15:0]Cmd,
output [127:0]PWM_Out,
input NE1,
input NWE,
input NOE,
inout [15:0]DAT,
input [15:0]ADDR
);
/*
REG_STA :    bit4				 bit3				 bit2				bit1		 bit0
					Ultras_Rdy	Press_Rdy		OPTF_Rdy		Mag_Rdy		A_G_T_Rdy
*/

//====================读写16位的地址===================
`define REG_CMD					16'd150
`define REG_STA					16'd151						//
`define REG_PWM1				16'd152
`define REG_PWM2				16'd153
`define REG_PWM3				16'd154
`define REG_PWM4				16'd155
`define REG_PWM5				16'd156
`define REG_PWM6				16'd157
`define REG_PWM7				16'd158
`define REG_PWM8				16'd159
`define OPFL_MOTION			16'd160
`define OPFL_SQUARL			16'd161
`define OPFL_DX					16'd162
`define OPFL_DY					16'd163
`define ALT_ULTRA				16'd164
//====================只读16位的地址===================
`define ACC_X_L					16'd0
`define ACC_X_H					16'd1
`define ACC_Y_L					16'd2
`define ACC_Y_H					16'd3
`define ACC_Z_L					16'd4
`define ACC_Z_H					16'd5
`define TMPER_L					16'd6
`define TMPER_H					16'd7
`define GYRO_X_L				16'd8
`define GYRO_X_H				16'd9
`define GYRO_Y_L				16'd10
`define GYRO_Y_H				16'd11
`define GYRO_Z_L				16'd12
`define GYRO_Z_H				16'd13
`define MAG_X_L					16'd14
`define MAG_X_H					16'd15
`define MAG_Y_L					16'd16
`define MAG_Y_H					16'd17
`define MAG_Z_L					16'd18
`define MAG_Z_H					16'd19
`define ALT_PRESS_L			16'd20
`define ALT_PRESS_H			16'd21

`define MPU_TIMESP_LL		16'd22
`define MPU_TIMESP_LH		16'd23
`define MPU_TIMESP_HL		16'd24
`define MPU_TIMESP_HH		16'd25

`define ADNS_TIMESP_LL	16'd26
`define ADNS_TIMESP_LH	16'd27
`define ADNS_TIMESP_HL	16'd28
`define ADNS_TIMESP_HH	16'd29

`define ARP_TIMESP_LL		16'd30
`define ARP_TIMESP_LH		16'd31
`define ARP_TIMESP_HL		16'd32
`define ARP_TIMESP_HH		16'd33

`define ULT_TIMESP_LL		16'd34
`define ULT_TIMESP_LH		16'd35
`define ULT_TIMESP_HL		16'd36
`define ULT_TIMESP_HH		16'd37

//================================================
reg [15:0]rCmd;
reg [15:0]rReg_Status;
reg [127:0]rPWM_Out;
reg Has_cmd;
reg [4:0]Clr_Rdy_flg; 

//======================================
wire Sig_Init_Rdy_NOE;
wire H2L_Sig_NOE;
wire L2H_Sig_NOE;
Sig_Edge_Detect NOE_Edge(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Sig_Init_Rdy_NOE), 
	.Pin_In( NOE ), 
	.H2L_Sig( H2L_Sig_NOE ), 
	.L2H_Sig( L2H_Sig_NOE )
);	
	
wire Sig_Init_Rdy_NE1;
wire H2L_Sig_NE1;
wire L2H_Sig_NE1;
Sig_Edge_Detect NE1_Edge(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Sig_Init_Rdy_NE1), 
	.Pin_In( NE1 ), 
	.H2L_Sig( H2L_Sig_NE1 ), 
	.L2H_Sig( L2H_Sig_NE1 )
);	
	
	
`define RDY_MPU_BIT	   4'd0
`define RDY_MAG_BIT	   4'd1
`define RDY_OPFL_BIT	 4'd2
`define RDY_ALT_PRESS_BIT	 4'd3
`define RDY_ALT_ULTRA_BIT	 4'd4

always @ ( posedge MPU_Rdy[0], posedge Clr_Rdy_flg[`RDY_MPU_BIT],negedge RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_MPU_BIT])
		rReg_Status[`RDY_MPU_BIT] <= 1'b0;
  else if(MPU_Rdy[0])
		rReg_Status[`RDY_MPU_BIT] <= 1'b1;

	
always @ ( posedge MPU_Rdy[1], posedge Clr_Rdy_flg[`RDY_MAG_BIT],negedge RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_MAG_BIT])
		rReg_Status[`RDY_MAG_BIT] <= 1'b0;
  else if(MPU_Rdy[1])
		rReg_Status[`RDY_MAG_BIT] <= 1'b1;

always @ ( posedge ADNS3080_Rdy, posedge Clr_Rdy_flg[`RDY_OPFL_BIT],negedge RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_OPFL_BIT])
		rReg_Status[`RDY_OPFL_BIT] <= 1'b0;
  else if(ADNS3080_Rdy)
		rReg_Status[`RDY_OPFL_BIT] <= 1'b1;
	
always @ ( posedge AirPress_Rdy, posedge Clr_Rdy_flg[`RDY_ALT_PRESS_BIT],negedge RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_ALT_PRESS_BIT])
		rReg_Status[`RDY_ALT_PRESS_BIT] <= 1'b0;
  else if(AirPress_Rdy)
		rReg_Status[`RDY_ALT_PRESS_BIT] <= 1'b1;

always @ ( posedge Ultra_Rdy, posedge Clr_Rdy_flg[`RDY_ALT_ULTRA_BIT],negedge RSTn)
	if(!RSTn||Clr_Rdy_flg[`RDY_ALT_ULTRA_BIT])
		rReg_Status[`RDY_ALT_ULTRA_BIT] <= 1'b0;
  else if(Ultra_Rdy)
		rReg_Status[`RDY_ALT_ULTRA_BIT] <= 1'b1;

	
reg [15:0]datbuf;
reg [2:0]sta;
always @( posedge CLK , negedge RSTn)
	if( !RSTn )begin
		sta <= 1'b0;
		datbuf <= 1'b0;
		rCmd <= 1'b0;
		Has_cmd <= 1'b1;
		rPWM_Out <= 16'd1000;
		Clr_Rdy_flg <= 1'b0;
	end
	else 
		case(sta)
		3'd0:
			if(!NE1&&Sig_Init_Rdy_NE1)
				sta <= sta + 1'b1;
			else 
				sta <= 3'd0;
		3'd1:
			if(!NOE)begin
				case(ADDR)
				//status
				`REG_STA:	datbuf <= rReg_Status;
				//MPU
				`ACC_X_L: begin	datbuf <= {MPU_Dat[7:0],MPU_Dat[15:8]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`ACC_X_H: 	datbuf <= 1'b0;			
				`ACC_Y_L: begin	datbuf <= {MPU_Dat[23:16],MPU_Dat[31:24]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`ACC_Y_H: 	datbuf <= 1'b0;			
				`ACC_Z_L: begin	datbuf <= {MPU_Dat[39:32],MPU_Dat[47:40]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`ACC_Z_H: 	datbuf <= 1'b0;			
				`TMPER_L: begin	datbuf <= {MPU_Dat[55:48],MPU_Dat[63:56]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`TMPER_H: 	datbuf <= 1'b0;		
				`GYRO_X_L:begin	datbuf <= {MPU_Dat[71:64],MPU_Dat[79:72]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`GYRO_X_H:	datbuf <= 1'b0;		
				`GYRO_Y_L:begin	datbuf <= {MPU_Dat[87:80],MPU_Dat[95:88]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`GYRO_Y_H:	datbuf <= 1'b0;		
				`GYRO_Z_L:begin	datbuf <= {MPU_Dat[103:96],MPU_Dat[111:104]};Clr_Rdy_flg[`RDY_MPU_BIT] <= 1'b1;end
				`GYRO_Z_H:	datbuf <= 1'b0;		
				`MAG_X_L:begin	datbuf <= MPU_Dat[127:112];Clr_Rdy_flg[`RDY_MAG_BIT] <= 1'b1;end
				`MAG_X_H:		datbuf <= 1'b0;		
				`MAG_Y_L:begin	datbuf <= MPU_Dat[143:128];Clr_Rdy_flg[`RDY_MAG_BIT] <= 1'b1;end
				`MAG_Y_H:		datbuf <= 1'b0;		
				`MAG_Z_L:begin	datbuf <= MPU_Dat[159:144];Clr_Rdy_flg[`RDY_MAG_BIT] <= 1'b1;end
				`MAG_Z_H:		datbuf <= 1'b0;
				`MPU_TIMESP_LL:begin datbuf <= MPU_Dat[175:160];end		//时间戳
				`MPU_TIMESP_LH:begin datbuf <= MPU_Dat[191:176];end
				`MPU_TIMESP_HL:begin datbuf <= MPU_Dat[207:192];end
				`MPU_TIMESP_HH:begin datbuf <= MPU_Dat[223:208];end
				//alt 5611
				`ALT_PRESS_L:begin	datbuf <= AirPress_Dat[15:0];Clr_Rdy_flg[`RDY_ALT_PRESS_BIT] <= 1'b1;end
				`ALT_PRESS_H:	datbuf <= AirPress_Dat[31:16];
				`ARP_TIMESP_LL:begin datbuf <= AirPress_Dat[47:32];end		//时间戳
				`ARP_TIMESP_LH:begin datbuf <= AirPress_Dat[63:48];end
				`ARP_TIMESP_HL:begin datbuf <= AirPress_Dat[79:64];end
				`ARP_TIMESP_HH:begin datbuf <= AirPress_Dat[95:80];end
				//optical flow
				`OPFL_MOTION: begin datbuf <= {8'd0,ADNS3080_Dat[7:0]};Clr_Rdy_flg[`RDY_OPFL_BIT] <= 1'b1;end
				`OPFL_SQUARL: begin datbuf <= {8'd0,ADNS3080_Dat[31:24]};Clr_Rdy_flg[`RDY_OPFL_BIT] <= 1'b1;end
				`OPFL_DX: begin datbuf <= {8'd0,ADNS3080_Dat[15:8]};Clr_Rdy_flg[`RDY_OPFL_BIT] <= 1'b1;end
				`OPFL_DY: begin datbuf <= {8'd0,ADNS3080_Dat[23:16]};Clr_Rdy_flg[`RDY_OPFL_BIT] <= 1'b1;end
				`ADNS_TIMESP_LL:begin datbuf <= ADNS3080_Dat[71:56];end		//时间戳
				`ADNS_TIMESP_LH:begin datbuf <= ADNS3080_Dat[87:72];end
				`ADNS_TIMESP_HL:begin datbuf <= ADNS3080_Dat[103:88];end
				`ADNS_TIMESP_HH:begin datbuf <= ADNS3080_Dat[119:104];end
				//ultrasonic
				`ALT_ULTRA:begin	datbuf <= Ultra_Dat[15:0];Clr_Rdy_flg[`RDY_ALT_ULTRA_BIT] <= 1'b1;end
				`ULT_TIMESP_LL:begin datbuf <= Ultra_Dat[31:16];end		//时间戳
				`ULT_TIMESP_LH:begin datbuf <= Ultra_Dat[47:32];end
				`ULT_TIMESP_HL:begin datbuf <= Ultra_Dat[63:48];end
				`ULT_TIMESP_HH:begin datbuf <= Ultra_Dat[79:64];end

				default: 	datbuf <= 1'b0;	
				endcase
				sta <= sta + 1'b1;
			end
			else if(!NWE)begin					//写操作
				case(ADDR)
				`REG_CMD:	begin rCmd <= DAT; Has_cmd <= 1'b1;end
				`REG_PWM1:begin rPWM_Out[15:0] <= DAT;end
				`REG_PWM2:begin rPWM_Out[31:16] <= DAT;end
				`REG_PWM3:begin rPWM_Out[47:32] <= DAT;end
				`REG_PWM4:begin rPWM_Out[63:48] <= DAT;end
				`REG_PWM5:begin rPWM_Out[79:64] <= DAT;end
				`REG_PWM6:begin rPWM_Out[95:80] <= DAT;end
				`REG_PWM7:begin rPWM_Out[111:96] <= DAT;end
				`REG_PWM8:begin rPWM_Out[127:112] <= DAT;end
				endcase
				sta <= sta + 1'b1;
			end
		3'd2:begin
			Has_cmd <= 1'b0;
			Clr_Rdy_flg <= 1'b0;												//脉冲信号复位
			if(NE1) 
				sta <= 3'd0;
			else
				sta <= 3'd2;
		end
		endcase
			
assign INT = (rReg_Status==0)? 1'b1 : 1'b0;
assign Cmd = rCmd;
assign PWM_Out = rPWM_Out;
assign DAT = (!NOE)? datbuf: 15'bz;
endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
