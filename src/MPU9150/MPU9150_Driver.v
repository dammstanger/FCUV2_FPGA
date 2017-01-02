/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：MPU9150_Driver
工程描述：9150的驱动 所用的I2C驱动由夏宇闻书改编
作	 者：dammstanger
日	 期：20160816
*************************************************************************/	
module MPU9150_Driver (
input CLK,
input CLK_SPI,
input PLL_Locked,
input RSTn,
input  En,
output SCL,
inout  SDA,
output Dat_Rdy_Sig,
input	 Rx_FIFO_RD_Req,
output [4:0]Rx_Dat_Cnt,
output [7:0]Rx_FIFO_dat,
output Time_Mark,
output [2:0]STA
);

/*********************************************************************************************************
	常量宏定义--9150设备地址
*********************************************************************************************************/
`define MPU_ADDR												7'h68				//7位的设备地址
`define AK8975_ADDR											7'h0c

/*********************************************************************************************************
常量宏定义--9150内部寄存器地址
*********************************************************************************************************/
`define MPU9150_RA_XG_OFFS_TC       	 8'h00 //[7] PWR_MODE, [6:1] XG_OFFS_TC, [0] OTP_BNK_VLD
`define MPU9150_RA_YG_OFFS_TC       	 8'h01 //[7] PWR_MODE, [6:1] YG_OFFS_TC, [0] OTP_BNK_VLD
`define MPU9150_RA_ZG_OFFS_TC       	 8'h02 //[7] PWR_MODE, [6:1] ZG_OFFS_TC, [0] OTP_BNK_VLD
`define MPU9150_RA_X_FINE_GAIN      	 8'h03 //[7:0] X_FINE_GAIN
`define MPU9150_RA_Y_FINE_GAIN      	 8'h04 //[7:0] Y_FINE_GAIN
`define MPU9150_RA_Z_FINE_GAIN      	 8'h05 //[7:0] Z_FINE_GAIN
`define MPU9150_RA_XA_OFFS_H        	 8'h06 //[15:0] XA_OFFS
`define MPU9150_RA_XA_OFFS_L_TC     	 8'h07
`define MPU9150_RA_YA_OFFS_H        	 8'h08 //[15:0] YA_OFFS
`define MPU9150_RA_YA_OFFS_L_TC     	 8'h09
`define MPU9150_RA_ZA_OFFS_H        	 8'h0A //[15:0] ZA_OFFS
`define MPU9150_RA_ZA_OFFS_L_TC     	 8'h0B
`define MPU9150_RA_XG_OFFS_USRH     	 8'h13 //[15:0] XG_OFFS_USR
`define MPU9150_RA_XG_OFFS_USRL     	 8'h14
`define MPU9150_RA_YG_OFFS_USRH     	 8'h15 //[15:0] YG_OFFS_USR
`define MPU9150_RA_YG_OFFS_USRL     	 8'h16
`define MPU9150_RA_ZG_OFFS_USRH     	 8'h17 //[15:0] ZG_OFFS_USR
`define MPU9150_RA_ZG_OFFS_USRL     	 8'h18
`define MPU9150_RA_SMPLRT_DIV       	 8'h19 //陀螺仪采样率，典型值：	 8'h07(125Hz)
`define MPU9150_RA_CONFIG           	 8'h1A //低通滤波频率，典型值：	 8'h06(5Hz)
`define MPU9150_RA_GYRO_CONFIG      	 8'h1B //陀螺仪自检及测量范围，典型值：	 8'h18(不自检，2000deg/s)
`define MPU9150_RA_ACCEL_CONFIG     	 8'h1C //加速计自检、测量范围及高通滤波频率，典型值：	 8'h01(不自检，2G，5Hz)
`define MPU9150_RA_FF_THR           	 8'h1D
`define MPU9150_RA_FF_DUR           	 8'h1E
`define MPU9150_RA_MOT_THR          	 8'h1F
`define MPU9150_RA_MOT_DUR          	 8'h20
`define MPU9150_RA_ZRMOT_THR        	 8'h21
`define MPU9150_RA_ZRMOT_DUR        	 8'h22
`define MPU9150_RA_FIFO_EN          	 8'h23
`define MPU9150_RA_I2C_MST_CTRL     	 8'h24
`define MPU9150_RA_I2C_SLV0_ADDR    	 8'h25
`define MPU9150_RA_I2C_SLV0_REG     	 8'h26
`define MPU9150_RA_I2C_SLV0_CTRL    	 8'h27
`define MPU9150_RA_I2C_SLV1_ADDR    	 8'h28
`define MPU9150_RA_I2C_SLV1_REG     	 8'h29
`define MPU9150_RA_I2C_SLV1_CTRL    	 8'h2A
`define MPU9150_RA_I2C_SLV2_ADDR    	 8'h2B
`define MPU9150_RA_I2C_SLV2_REG     	 8'h2C
`define MPU9150_RA_I2C_SLV2_CTRL    	 8'h2D
`define MPU9150_RA_I2C_SLV3_ADDR    	 8'h2E
`define MPU9150_RA_I2C_SLV3_REG     	 8'h2F
`define MPU9150_RA_I2C_SLV3_CTRL    	 8'h30
`define MPU9150_RA_I2C_SLV4_ADDR    	 8'h31
`define MPU9150_RA_I2C_SLV4_REG     	 8'h32
`define MPU9150_RA_I2C_SLV4_DO      	 8'h33
`define MPU9150_RA_I2C_SLV4_CTRL    	 8'h34
`define MPU9150_RA_I2C_SLV4_DI      	 8'h35
`define MPU9150_RA_I2C_MST_STATUS   	 8'h36
`define MPU9150_RA_INT_PIN_CFG      	 8'h37			//中断和管脚配置
`define MPU9150_RA_INT_ENABLE       	 8'h38
`define MPU9150_RA_DMP_INT_STATUS   	 8'h39
`define MPU9150_RA_INT_STATUS       	 8'h3A
`define MPU9150_RA_ACCEL_XOUT_H     	 8'h3B			//X轴加速度数据寄存器高位
`define MPU9150_RA_ACCEL_XOUT_L     	 8'h3C
`define MPU9150_RA_ACCEL_YOUT_H     	 8'h3D
`define MPU9150_RA_ACCEL_YOUT_L     	 8'h3E
`define MPU9150_RA_ACCEL_ZOUT_H     	 8'h3F
`define MPU9150_RA_ACCEL_ZOUT_L     	 8'h40
`define MPU9150_RA_TEMP_OUT_H       	 8'h41
`define MPU9150_RA_TEMP_OUT_L       	 8'h42
`define MPU9150_RA_GYRO_XOUT_H      	 8'h43
`define MPU9150_RA_GYRO_XOUT_L      	 8'h44
`define MPU9150_RA_GYRO_YOUT_H      	 8'h45
`define MPU9150_RA_GYRO_YOUT_L      	 8'h46
`define MPU9150_RA_GYRO_ZOUT_H      	 8'h47
`define MPU9150_RA_GYRO_ZOUT_L      	 8'h48
`define MPU9150_RA_EXT_SENS_DATA_00 	 8'h49
`define MPU9150_RA_EXT_SENS_DATA_01 	 8'h4A
`define MPU9150_RA_EXT_SENS_DATA_02 	 8'h4B
`define MPU9150_RA_EXT_SENS_DATA_03 	 8'h4C
`define MPU9150_RA_EXT_SENS_DATA_04 	 8'h4D
`define MPU9150_RA_EXT_SENS_DATA_05 	 8'h4E
`define MPU9150_RA_EXT_SENS_DATA_06 	 8'h4F
`define MPU9150_RA_EXT_SENS_DATA_07 	 8'h50
`define MPU9150_RA_EXT_SENS_DATA_08 	 8'h51
`define MPU9150_RA_EXT_SENS_DATA_09 	 8'h52
`define MPU9150_RA_EXT_SENS_DATA_10 	 8'h53
`define MPU9150_RA_EXT_SENS_DATA_11 	 8'h54
`define MPU9150_RA_EXT_SENS_DATA_12 	 8'h55
`define MPU9150_RA_EXT_SENS_DATA_13 	 8'h56
`define MPU9150_RA_EXT_SENS_DATA_14 	 8'h57
`define MPU9150_RA_EXT_SENS_DATA_15 	 8'h58
`define MPU9150_RA_EXT_SENS_DATA_16 	 8'h59
`define MPU9150_RA_EXT_SENS_DATA_17 	 8'h5A
`define MPU9150_RA_EXT_SENS_DATA_18 	 8'h5B
`define MPU9150_RA_EXT_SENS_DATA_19 	 8'h5C
`define MPU9150_RA_EXT_SENS_DATA_20 	 8'h5D
`define MPU9150_RA_EXT_SENS_DATA_21 	 8'h5E
`define MPU9150_RA_EXT_SENS_DATA_22 	 8'h5F
`define MPU9150_RA_EXT_SENS_DATA_23 	 8'h60
`define MPU9150_RA_MOT_DETECT_STATUS    	 8'h61
`define MPU9150_RA_I2C_SLV0_DO      	 8'h63
`define MPU9150_RA_I2C_SLV1_DO      	 8'h64
`define MPU9150_RA_I2C_SLV2_DO      	 8'h65
`define MPU9150_RA_I2C_SLV3_DO      	 8'h66
`define MPU9150_RA_I2C_MST_DELAY_CTRL   	 8'h67
`define MPU9150_RA_SIGNAL_PATH_RESET    	 8'h68
`define MPU9150_RA_MOT_DETECT_CTRL      	 8'h69
`define MPU9150_RA_USER_CTRL        	 8'h6A
`define MPU9150_RA_PWR_MGMT_1       	 8'h6B	//电源管理，典型值：	 8'h00(正常启用)
`define MPU9150_RA_PWR_MGMT_2       	 8'h6C
`define MPU9150_RA_BANK_SEL         	 8'h6D
`define MPU9150_RA_MEM_START_ADDR   	 8'h6E
`define MPU9150_RA_MEM_R_W          	 8'h6F
`define MPU9150_RA_DMP_CFG_1        	 8'h70
`define MPU9150_RA_DMP_CFG_2        	 8'h71
`define MPU9150_RA_FIFO_COUNTH      	 8'h72
`define MPU9150_RA_FIFO_COUNTL      	 8'h73
`define MPU9150_RA_FIFO_R_W         	 8'h74
`define MPU9150_RA_WHO_AM_I         	 8'h75	//IIC地址寄存器(默认数值	 8'h68，9脚AD0接高时为	 8'h69只读)


`define MPU9150_ADDRESS_AD0_LOW     	 8'h68 // address pin low (GND), default for InvenSense evaluation board
`define MPU9150_ADDRESS_AD0_HIGH    	 8'h69 // address pin high (VCC)

//***************AK8975寄存器地址***************************
`define AK8975_WIA        	 						8'h00 //DEVICE_ID：48H		(Read-only register)
`define AK8975_INFO        	 						8'h01 //Information				(Read-only register)
`define AK8975_ST1        	 						8'h02 //status
`define AK8975_HXL        	 						8'h03 //Measurement Data
`define AK8975_HXH        	 						8'h04 //Measurement Data
`define AK8975_HYL        	 						8'h05 //Measurement Data
`define AK8975_HYH        	 						8'h06 //Measurement Data
`define AK8975_HZL        	 						8'h07 //Measurement Data
`define AK8975_HZH        	 						8'h08 //Measurement Data
`define AK8975_ST2        	 						8'h09 //status2
`define AK8975_CNTL       	 						8'h0a //control
`define AK8975_ASTC       	 						8'h0c //Self Test Control
`define AK8975_TS1       	 							8'h0d //Self Test Control
`define AK8975_TS2	       	 						8'h0e //Self Test Control
`define AK8975_I2CDIS      	 						8'h0f //Self Test Control
`define AK8975_ASAX       	 						8'h10 //Sensitivity Adjustment values(Read-only register)
`define AK8975_ASAY       	 						8'h11 //Sensitivity Adjustment values
`define AK8975_ASAZ       	 						8'h12 //Sensitivity Adjustment values

/*********************************************************************************************************
	常量宏定义--9150内部寄存器常值，设定值
*********************************************************************************************************/
`define MPU9150_I_AM_ID									8'h68
`define AK8975_I_AM_ID									8'h48



//*****************I2C通信模块变量****************
reg WR,RD;
wire Byte_Rx_RDY;
wire ACK;
reg [4:0]READ_NUM;		//支持32字节
wire [7:0]DATA_R;
reg [7:0]DATA_S;
reg [7:0]REG_ADDR;
reg [6:0]DIV_ADDR;
//******************接收FIFO***********************

reg Rx_Aclr;
reg Rx_FIFO_WR_Req;
wire Rx_FIFO_Full;
wire Rx_Empty_Sig;


FIFO_8_32	FIFO_9150Rx(
	.clock ( CLK ),
	.aclr (Rx_Aclr),
	.data ( DATA_R ),
	.rdreq ( Rx_FIFO_RD_Req ),
	.wrreq ( Rx_FIFO_WR_Req ),
	.empty ( Rx_Empty_Sig ),
	.full ( Rx_FIFO_Full ),
	.usedw(Rx_Dat_Cnt),
	.q ( Rx_FIFO_dat )
	);

//*****************I2C 模块的相应信号检测**********
wire ACK_L2H;
wire ACK_H2L;
InerSig_Edge_Detect ACK_Edge_Detect(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Sig_In( ACK ), 
	.H2L_Sig( ACK_H2L ), 
	.L2H_Sig( ACK_L2H )
);	
	
wire Rx_RDY_L2H;
InerSig_Edge_Detect Rx_RDY_Edge_Detect(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Sig_In( Byte_Rx_RDY ),  
	.L2H_Sig( Rx_RDY_L2H )
);	
//***************延时**************************
reg En_delay;
reg [15:0]delay_cnt;
wire dy_timup;

delayNus_module delayNus_module_9150(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_delay),
	.Nus(delay_cnt),
	.timeup(dy_timup)
);

//***************循环脉冲**************************
wire vclk;
delayNms_cyc_module #(16'd2)delayNms_9150(				//2ms一个脉冲
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk( vclk )	
);


/****************总状态机********************/
	 parameter 	CHK = 3'd0,
							INIT = 3'd1,
							IDLE = 3'd2,
							REV  = 3'd3,
							SEND = 3'd4,
							REST = 3'd5,
							ERR	 = 3'd7;
							
	parameter  DELAY = 5'd29;
	
	reg [2:0]sta_9150;
	reg [2:0]sta_9150_lst;
	reg [4:0]substp;
	reg [4:0]substp_lst;
	reg first;
	reg [2:0]MAG_samp_cnt;
	reg [3:0]err_cnt;
	reg [4:0]cnt;
	reg rDat_Rdy;
	reg rTime_Mark;

always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		WR <= 1'b0;
		RD <= 1'b0;
		En_delay <= 1'b0;
		delay_cnt<= 1'b0;
		sta_9150 <= CHK;
		sta_9150_lst <= CHK;
		substp <= 1'b0;
		substp_lst <= 1'b0;
		DATA_S <= 8'b0;
		REG_ADDR <= 8'b0;
		DIV_ADDR <= 7'b0;
		first <= 1'b1;
		MAG_samp_cnt <= 1'b0;
		err_cnt <= 1'b0;
		cnt <= 1'b0;
		rDat_Rdy <= 1'b0;
		rTime_Mark <= 1'b0;
		READ_NUM <= 1'b1;
	end
	else begin
		En_delay <= 1'b0;
		rDat_Rdy <= 1'b0;
		rTime_Mark <= 1'b0;
		if(En)
			case(sta_9150)
			CHK:begin
				case(substp)
				5'd0://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						RD 				<= 1'b1;
						READ_NUM	<= 1'b1;
						DIV_ADDR 	<= `MPU_ADDR;
						REG_ADDR 	<= `MPU9150_RA_WHO_AM_I;			//75h ID 寄存器
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						RD 				<= 1'b0;
						if(DATA_R==`MPU9150_I_AM_ID)begin				//68h
							err_cnt <= 1'b0;
							substp <= substp + 1'b1;
						end
						else begin
							err_cnt <= err_cnt + 1'b1;
							if(err_cnt==4'd4)begin
								err_cnt <= 1'b0;
								substp <= 1'b0;
								sta_9150 <= ERR;
								sta_9150_lst <= sta_9150;
							end
						end
					end
				5'd1://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						RD 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_PWR_MGMT_1;			//6bh 电源管理	解除休眠状态
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						RD 				<= 1'b0;
						if(DATA_R&8'h80)begin									//器件正在复位
							delay_cnt <= 16'd1000;
							En_delay 	<= 1'b1;
							substp 		<= DELAY;
							substp_lst<= substp;
						end
						else if(DATA_R&8'h40)									//器件正在睡觉
							substp 		<= substp + 1'b1;
						else
							substp <= 5'd3;
					end
				5'd2://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_PWR_MGMT_1;		//37h I2C_BYPASS_EN IIC 直通
						DATA_S			<= 8'h00;
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd1000;									//从睡眠唤醒需要等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;							//延时回来时直接到下一步
					end
				5'd3://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_INT_PIN_CFG;		//37h I2C_BYPASS_EN IIC 直通
						DATA_S			<= 8'h92;
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						substp 		<= substp + 1'b1;
					end
				5'd4://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_USER_CTRL;			//6ah MPU9150不做主机
						DATA_S			<= 8'h00;
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						substp 		<= substp + 1'b1;
					end
				5'd5://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						RD 				<= 1'b1;
						DIV_ADDR 	<= `AK8975_ADDR;
						REG_ADDR 	<= `AK8975_WIA;								//AK8975_ID
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						RD 				<= 1'b0;
						substp <= 1'b0;
						if(DATA_R==`AK8975_I_AM_ID)begin
							sta_9150 <= INIT;
							sta_9150_lst <= sta_9150;
						end
						else begin
							sta_9150 <= ERR;
							sta_9150_lst <= sta_9150;
						end
					end
				DELAY://----------------------------------------------------
					if(dy_timup)begin
						substp <= substp_lst;
					end
				endcase
			end
			INIT:begin
				case(substp)
				5'd0://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						DIV_ADDR 	<= `MPU_ADDR;
						REG_ADDR 	<= `MPU9150_RA_SMPLRT_DIV;			//19h 采样率设置Sample Rate = Gyroscope Output Rate(1kHz) / (1 + SMPLRT_DIV)=500Hz 2ms
						DATA_S 		<= 8'b1;
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;										//等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd1://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_CONFIG;					//1ah 对ACC和GYRO的低通滤波器42Hz LP
						DATA_S 		<= 8'h03;
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;										//等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd2://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_GYRO_CONFIG;					//1bh 陀螺仪的量程FS_SEL=3： ± 2000 °/s
						DATA_S 		<= 8'h18;
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;										//等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd3://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_ACCEL_CONFIG;		//1bh AFS_SEL=2  ± 8g
						DATA_S 		<= 8'h10;												//
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;										//等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd4://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `MPU9150_RA_INT_ENABLE;		//DATA_RDY_EN=1 使能数据准备好中断
						DATA_S 		<= 8'h01;												//
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;										//等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd5://*********************AKM初始化**********************************
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						DIV_ADDR 	<= `AK8975_ADDR;
						REG_ADDR 	<= `AK8975_CNTL;								//读ROM模式
						DATA_S 		<= 8'h0f;												//
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;										//等待些时间
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd6://------------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						RD 				<= 1'b1;
						READ_NUM	<= 5'd3;
						REG_ADDR 	<= `AK8975_ASAX;									//读ROM模式 起始地址 返回值[A2 A0 AF]
					end
					else if(Rx_RDY_L2H)begin
						cnt				<= cnt + 1'b1;
					end
					else if(ACK_H2L)begin
						rDat_Rdy	<= 1'b1;
						first 		<= 1'b1;
						RD				<= 1'b0;
						cnt				<= 1'b0;
						substp		<= substp + 1'b1;
					end
				5'd7://------------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						WR 				<= 1'b1;
						REG_ADDR 	<= `AK8975_CNTL;								//power down 模式
						DATA_S 		<= 8'h00;												//
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						delay_cnt <= 16'd100;											//等待些时间>=100us
						En_delay 	<= 1'b1;
						substp 		<= DELAY;
						substp_lst<= substp + 1'b1;								//延时回来时直接到下一步
					end
				5'd8:begin
						substp 		<= 1'b0;
						substp_lst<= 1'b0;	
						sta_9150  <= IDLE;
						sta_9150_lst <= sta_9150;
					end
				DELAY://----------------------------------------------------
					if(dy_timup)begin
						substp <= substp_lst;
					end
				endcase
			end
			IDLE:begin
				if(vclk)begin
					sta_9150 <= SEND;
				end
				else
					sta_9150 <= IDLE;
			end
			SEND:begin
				case(substp)
				5'd0://----------------------------------------------------
					if(first)begin
						first 		<= 1'b0;
						RD 				<= 1'b1;
						READ_NUM	<= 5'd14;
						DIV_ADDR 	<= `MPU_ADDR;
						REG_ADDR 	<= `MPU9150_RA_ACCEL_XOUT_H;			//14个数据寄存器的起始地址
					end
					else if(ACK_H2L)begin
						first 				<= 1'b1;
						RD						<= 1'b0;
						rTime_Mark 		<= 1'b1;											//先于rDat_Rdy动作留出盖戳时间
						if(MAG_samp_cnt==4)begin										//时隔5个vclk周期一共10ms
							substp				<= substp + 1'b1;
							MAG_samp_cnt	<= 1'b0;
						end
						else begin
							MAG_samp_cnt	<= MAG_samp_cnt + 1'b1;
							substp				<= 5'd3;			//跳至发送数据就绪标记
						end
					end
				5'd1:
				if(first)begin															//先读取上回的测量值
						first 		<= 1'b0;
						RD 				<= 1'b1;
						READ_NUM	<= 5'd6;
						DIV_ADDR 	<= `AK8975_ADDR;							//
						REG_ADDR 	<= `AK8975_HXL;								//测量数据寄存器组低位：X轴数值的高字节
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						RD				<= 1'b0;
						substp 		<= substp + 1'b1;	
					end
				5'd2:
					if(first)begin														//读取之后启动此次测量，启动后立即读取，值无意义
						first 		<= 1'b0;
						WR 				<= 1'b1;
						DIV_ADDR 	<= `AK8975_ADDR;
						REG_ADDR 	<= `AK8975_CNTL;								//单次采集模式
						DATA_S 		<= 8'h01;												//
					end
					else if(ACK_H2L)begin
						first 		<= 1'b1;
						WR 				<= 1'b0;
						substp		<= 5'd3;			//跳至发送数据就绪标记
					end
			  5'd3:begin
					rDat_Rdy  <= 1'b1;				 //数据就绪
					substp		<= 1'b0;				 //复位状态机
					sta_9150 	<= IDLE;				
				end
				endcase
			end
			endcase
	end
//**********************FIFO存储********************************	

reg [1:0]sta_FIFO;
always @ ( posedge CLK or negedge RSTn )

	if( !RSTn )begin
		Rx_Aclr <= 1'b1;
		sta_FIFO <= 1'b0;
	end
	else begin
		Rx_Aclr	<= 1'b0;
		case(sta_FIFO)
		2'd0:
		if(vclk&&(!Rx_Empty_Sig))begin			//如果FIFO不空，则先清空
				Rx_Aclr <= 1'b1;
				sta_FIFO <= sta_FIFO + 2'd2;	
			end		
			else if(Rx_RDY_L2H)begin
				Rx_FIFO_WR_Req <= 1'b1;
				sta_FIFO <= sta_FIFO + 2'd1;
			end
			else
				sta_FIFO <= 1'b0;
		2'd1:begin
			Rx_FIFO_WR_Req <= 1'b0;
			sta_FIFO <= 1'b0;
		end
		2'd2:begin
			sta_FIFO <= 2'd0;
		end

		endcase
	end

wire I2C_2_Clk;
I2C_CLK_Gener #(9'd400)I2C_CLK_Gener_U1(			//速率400k
	.CLK( CLK_SPI ),
	.RSTn( RSTn ),
	.En(PLL_Locked),
	.Clkout(I2C_2_Clk)
);

I2C_module I2C_module_U2(										
	.CLK( I2C_2_Clk ),
	.RSTn( RSTn ),
	.SCL(SCL),
	.SDA(SDA),
	.Rx_RDY(Byte_Rx_RDY),
	.ACK(ACK),
	.WR(WR),
	.RD(RD),
	.NUM(READ_NUM),
	.DIV_ADDR(DIV_ADDR),
	.ADDR(REG_ADDR),
	.DATA_IN(DATA_S),
	.DATA_OUT(DATA_R)
);


assign STA = sta_9150;
assign Dat_Rdy_Sig = rDat_Rdy;
assign Time_Mark = rTime_Mark;
endmodule



/**********************END OF FILE COPYRIGHT @2016************************/	
