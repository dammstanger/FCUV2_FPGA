/**********************DAMMSTANGER COPYRIGHT @2016************************
�������ƣ�adns3080_Driver
����������SPI2401��������д24L01�Ĵ�����
���ص�SROM�汾��Ϊ��0x51
��ʼ���������ֱ��ʣ�1600	
					 ֡�ʣ��Զ� 2000-6469f/s ��Ĭ�ϣ�
					 ���ţ��Զ� ���8192			��Ĭ�ϣ�
��	 �ߣ�dammstanger
��	 �ڣ�20160810
*************************************************************************/	
module adns3080_Driver (
input  CLK,
input  RSTn,
input  En,
output CSN,
output RST,
input  SPI_Busy_Flg,
input  SPI_RxDat_Rdy,
output [7:0]SBUF,
input  [7:0]RBUF,
input  Rx_FIFO_RD_Req,
output [7:0]Rx_FIFO_dat,
output Rx_FIFO_Full,
output En_SPI,
output [2:0]Rx_Dat_Cnt,
output [7:0]dat_out,
output Time_Mark,
output [2:0]sta_out
);


/*********************************************************************************************************
	�����궨��--ADNS3080�ڲ��Ĵ���ָ��
*********************************************************************************************************/
`define ADNSD3080_WRITE								 8'h80
`define ADNSD3080_READ								 8'h00

/*********************************************************************************************************
	�����궨��--ADNS3080(SPI)�ڲ��Ĵ�����ַ
*********************************************************************************************************/
`define ADNS3080_PRODUCT_ID            8'h00
`define ADNS3080_REVISION_ID           8'h01
`define ADNS3080_MOTION                8'h02
`define ADNS3080_DELTA_X               8'h03
`define ADNS3080_DELTA_Y               8'h04
`define ADNS3080_SQUAL                 8'h05
`define ADNS3080_PIXEL_SUM             8'h06
`define ADNS3080_MAXIMUM_PIXEL         8'h07
`define ADNS3080_CONFIGURATION_BITS    8'h0a
`define ADNS3080_EXTENDED_CONFIG       8'h0b
`define ADNS3080_DATA_OUT_LOWER        8'h0c
`define ADNS3080_DATA_OUT_UPPER        8'h0d
`define ADNS3080_SHUTTER_LOWER         8'h0e
`define ADNS3080_SHUTTER_UPPER         8'h0f
`define ADNS3080_FRAME_PERIOD_LOWER    8'h10
`define ADNS3080_FRAME_PERIOD_UPPER    8'h11
`define ADNS3080_MOTION_CLEAR          8'h12
`define ADNS3080_FRAME_CAPTURE         8'h13
`define ADNS3080_SROM_ENABLE           8'h14
`define ADNS3080_FRAME_PERIOD_MAX_BOUND_LOWER      8'h19
`define ADNS3080_FRAME_PERIOD_MAX_BOUND_UPPER      8'h1a
`define ADNS3080_FRAME_PERIOD_MIN_BOUND_LOWER      8'h1b
`define ADNS3080_FRAME_PERIOD_MIN_BOUND_UPPER      8'h1c
`define ADNS3080_SHUTTER_MAX_BOUND_LOWER           8'h1d
`define ADNS3080_SHUTTER_MAX_BOUND_UPPER           8'h1e
`define ADNS3080_SROM_ID               	8'h1f
`define ADNS3080_OBSERVATION           	8'h3d
`define ADNS3080_INVERSE_PRODUCT_ID    	8'h3f
`define ADNS3080_PIXEL_BURST           	8'h40
`define ADNS3080_MOTION_BURST          	8'h50
`define ADNS3080_SROM_LOAD             	8'h60

`define ADNS3080_SROM_REG1							8'h20
`define ADNS3080_SROM_REG2							8'h23
`define ADNS3080_SROM_REG3							8'h24

/*********************************************************************************************************
	ADNS3080��ʼ���Ĵ����ĳ�ֵ
*********************************************************************************************************/
//ADNS3080 reset value 
`define ADNS3080_ID											8'h17

// ADNS3080 hardware config
`define ADNS3080_PIXELS_X               30
`define ADNS3080_PIXELS_Y               30
`define ADNS3080_CLOCK_SPEED            24000000

`define ADNS3080_RESOLUTION_400        	400
`define ADNS3080_RESOLUTION_1600       	1600



`define ADNS3080_FRAME_RATE_MAX         6469
`define ADNS3080_FRAME_RATE_MIN         2000

`define OPTICALFLOW_ANGLE_LIMIT_MAX		45



/***************Nmsѭ����ʱ�� ���ڲɼ���ȡ���ڿ���*******************/
wire vclk;
delayNms_cyc_module #(16'd100)delayNms_cyc_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk(vclk)
);


/***************us��ʱ��1 ���ڶ�д״̬���Զ�дʱ���е���ʱ����*******************/
reg En_delay1;
reg [15:0]delay1_cnt;
wire delay1_tup;

delayNus_module delayNus_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_delay1 ),
	.Nus( delay1_cnt ),
	.timeup(delay1_tup)
);

/***************us��ʱ��2 ������״̬���Զ�дʱ���е���ʱ����*******************/
reg En_delay2;
reg [15:0]delay2_cnt;
wire delay2_tup;

delayNus_module delayNus_module_U2(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_delay2 ),
	.Nus( delay2_cnt ),
	.timeup(delay2_tup)
);

/******************����FIFO***********************/

parameter Rx_Aclr=1'b0;
reg Rx_FIFO_WR_Req;
wire Rx_Empty_Sig;
	

FIFO_8_32	FIFO_3080Rx(
	.clock ( CLK ),
	.aclr (Rx_Aclr),
	.data ( RBUF ),
	.rdreq ( Rx_FIFO_RD_Req ),
	.wrreq ( Rx_FIFO_WR_Req ),
	.empty ( Rx_Empty_Sig ),
	.full ( Rx_FIFO_Full ),
	.usedw(Rx_Dat_Cnt),
	.q ( Rx_FIFO_dat )
	);

/******************adns3080��SROM***********************/
reg [10:0]SROM_Addr;
wire [7:0]SROM_Dat;
wire SROM_Clk;

SROM	SROM_inst (
	.address ( SROM_Addr ),
	.clock ( SROM_Clk ),
	.q ( SROM_Dat )
);

/****************��ȡ���ֲ���*********************/

reg [1:0]sta_rr;
reg [7:0]ADNS_regdat;

/****************��д�Ĵ������̲���********************/
reg [3:0]sta_rw;
reg [3:0]substp;
reg [7:0]cmd;
reg [10:0]size;
reg [7:0]wr_buf;
reg [7:0]rSBUF;
reg rCSN;
reg rRST;
reg rEn_SPI;
reg RW_done;					//��д������ɱ�־
reg [10:0]cnt_rw;
reg rTime_Mark;

/****************��״̬��********************/
	 parameter 	CHK = 3'd0,
							INIT = 3'd1,
							IDLE = 3'd2,
							REV  = 3'd3,
							SEND = 3'd4,
							REST = 3'd5;
	 
	 reg rEnBuadcnt;
	 reg [2:0]sta_3080;
	 reg [2:0]sta_3080_lst;
	 reg [4:0]stp;
	 reg En_RW;
	 reg first;
	 reg En_wFIFO;
	 /****************************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_3080 <= REST;
		sta_3080_lst <= REST;
		stp <= 1'b0;
		En_RW <= 1'b0;
		En_wFIFO <= 1'b0;
		first <= 1'b1;
		cmd <= 1'b0;
		size <= 1'b0;
		rRST <= 1'b0;
		En_delay2 <= 1'b0;
		delay2_cnt <= 16'd20;
		wr_buf <= 8'h11;				//
		rTime_Mark <= 1'b0;
	end 
	else begin
	En_delay2 <= 1'b0;	//�����źŸ�λ�ڴ�
	En_RW <= 1'b0;
	rTime_Mark <= 1'b0;
	if(En)
		case(sta_3080)
		REST:begin
			case(stp)
			4'd0:begin
				rRST <= 1'b1;
				En_delay2 <= 1'b1;
				stp <= stp + 1'b1;			
			end
			4'd1:
				if(delay2_tup)begin
					rRST <= 1'b0;
					En_delay2 <= 1'b1;
					delay2_cnt <= 16'd500;			//��λ����ʱ
					stp <= stp + 1'b1;			
				end
			4'd2:
				if(delay2_tup)begin
					if(sta_3080_lst==INIT)begin
						stp <= 4'd1;
						sta_3080 <= INIT;
					end
					else begin
						stp <= 1'b0;
						sta_3080 <= CHK;
					end
				end
			endcase
		end
		CHK:begin
			case(stp)
			4'd0:
			if(first)begin
				En_RW <= 1'b1;
				first <= 1'b0;
				cmd <= `ADNSD3080_READ|`ADNS3080_PRODUCT_ID;  size <= 11'd1; 
			end
			else if(RW_done)begin
				if(ADNS_regdat!=`ADNS3080_ID)begin													//�ж��Ƿ����豸3080
					sta_3080 <= REST;
					sta_3080_lst <= sta_3080;
				end
				else 
					stp <= stp + 1'b1;
				first <= 1'b1;
			end
			4'd1:
			if(first)begin
				En_RW <= 1'b1;
				first <= 1'b0;
				cmd <= `ADNSD3080_READ|`ADNS3080_INVERSE_PRODUCT_ID;  size <= 11'd1; 
			end
			else if(RW_done)begin
				first <= 1'b1;
				stp <= 1'b0;
				sta_3080 <= INIT;
			end
			endcase
		end
		INIT:begin
			case(stp)
			4'd0:begin
				sta_3080 <= REST;							//����romǰ��λ
				delay2_cnt <= 16'd500;					//��λ��С10us
				sta_3080_lst <= sta_3080;
				stp <= 1'b0;
			end
			4'd1:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_SROM_REG1;  size <= 11'b1; 	//д�Ĵ���0x20
					wr_buf <= 8'h44;
				end		
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end		
			end
			4'd2:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_SROM_REG2;  size <= 11'b1; 	//д�Ĵ���0x23
					wr_buf <= 8'h07;
				end		
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end		
			end
			4'd3:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_SROM_REG3;  size <= 11'b1; 	//д�Ĵ���0x24
					wr_buf <= 8'h88;
				end		
				else if(RW_done)begin
					first <= 1'b1;
					En_delay2 <= 1'b1;
					delay2_cnt <= 16'd500;			//��ʱ500us	��2000֡/sΪ�����ʱ
					stp <= stp + 1'b1;
				end		
			end
			4'd4:
			if(delay2_tup)
				stp <= stp + 1'b1;	
			4'd5:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_SROM_ENABLE;  size <= 11'b1; 	//д�Ĵ���0x14
					wr_buf <= 8'h18;
				end		
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end		
			end
			4'd6:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_SROM_LOAD;  size <= 11'd1986; 	 //дSROM
				end		
				else if(RW_done)begin
					first <= 1'b1;
					En_delay2 <= 1'b1;
					delay2_cnt <= 16'd100;			//��ʱ100us
					stp <= stp + 1'b1;
				end	
			end	
			4'd7:
				if(delay2_tup)
					stp <= stp + 1'b1;	
			4'd8:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_SROM_ID;  size <= 11'b1; 	//��ȡSROM ��id ���Ϊ0x00�����ʧ��
				end																														//��SROM�汾��Ϊ 0x51
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end
			end
			4'd9:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_CONFIGURATION_BITS;  size <= 11'b1; 	//д�Ĵ���0x0a
					wr_buf <= 8'h10;											//0x10 �ֱ��ʣ�1600 0x00 �ֱ��ʣ�400
				end						
				else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			4'd10:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_OBSERVATION;  size <= 11'b1; 	//���Ĵ���0x3d ֵ0x9x
				end							
				else if(RW_done)begin
						first <= 1'b1;
//						stp <= stp + 1'b1;
						stp <= 5'd19;												//��������ѡΪĬ�ϣ���������
					end
				end
			4'd11:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_CONFIGURATION_BITS;  size <= 11'b1; 	//���Ĵ���0x0a ӦΪ��0x10
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			4'd12:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_EXTENDED_CONFIG;  size <= 11'b1; 	//���Ĵ���0x0bӦΪ��0x00 ���ţ�֡�Զ�
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			4'd13:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_FRAME_PERIOD_MAX_BOUND_UPPER;  size <= 11'b1; 	//�����ȸߺ�� д���ȵͺ��
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			5'd14:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_FRAME_PERIOD_MAX_BOUND_LOWER;  size <= 11'b1; 	//���Ĵ���0x0bӦΪ��0x00 ֡�Զ�
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			5'd15:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_FRAME_PERIOD_MIN_BOUND_UPPER;  size <= 11'b1; 	//�����ȸߺ�� д���ȵͺ��
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			5'd16:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_FRAME_PERIOD_MIN_BOUND_LOWER;  size <= 11'b1; 	//���Ĵ���0x0bӦΪ��0x00 ֡�Զ�
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			5'd17:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_SHUTTER_MAX_BOUND_UPPER;  size <= 11'b1; 	//�����ȸߺ�� д���ȵͺ��
				end							
			else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
			5'd18:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_SHUTTER_MAX_BOUND_LOWER;  size <= 11'b1; 	//���Ĵ���0x0a
				end							
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end		
			end
			5'd19:begin
				stp <= 1'b0;
				sta_3080 <= IDLE;
				sta_3080_lst <= sta_3080;
			end
			endcase
		end
		IDLE:begin									/****************standby*****************/
		//�޷��Ͳ���ʱ����3080���ڲ�ѯģʽ
			if(vclk)begin
				sta_3080 <= SEND;
				sta_3080_lst <= sta_3080;
			end
		end
		SEND:begin									/****************���Ͳ���*********************/
			case(stp)
			4'd0:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					En_wFIFO <= 1'b1;
					cmd <= `ADNSD3080_READ|`ADNS3080_MOTION_BURST;  size=11'd7; 
				end			//����������˳��motion ,dx,dy,SQUAL,shutter up, shutter low,Maximum Pixel value	(0-63)
				else if(RW_done)begin
					first <= 1'b1;
					rTime_Mark <= 1'b1;						//�ɼ���ɣ�����ʱ���
					En_wFIFO <= 1'b0;
					stp <= stp + 4'd4;
				end	
			end
			4'd4:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADNSD3080_WRITE|`ADNS3080_MOTION_CLEAR;  size <= 11'b1; 	
				end				//�κ�ֵд�Ĵ���0x12 ���������ؼĴ���
				else if(RW_done)begin
					first <= 1'b1;
					stp <= 1'b0;
					sta_3080 <= IDLE;
					sta_3080_lst <= sta_3080;				
				end					
			end
			endcase
		end
		endcase
	end
	

/*******************SROM�Ķ�ȡ*********************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		SROM_Addr <= 1'b0;
	end
	else if(cnt_rw<=1985)			//����
		SROM_Addr <= cnt_rw;
	else
		SROM_Addr <= 1'b0;

assign SROM_Clk =(cmd==(`ADNSD3080_WRITE|`ADNS3080_SROM_LOAD))? CLK : 1'b0;


/*******************��д�ֽ����̣�����SPIģ����ɶ�д*********************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_rw 	<= 4'd0;
		substp 	<= 1'b0;
		rCSN 		<= 1'b1;
		rEn_SPI <= 1'b0;
		cnt_rw 	<= 1'd0;
		rSBUF 	<= 1'b0;
		RW_done <= 1'b0;
		En_delay1 <= 1'b0;
		delay1_cnt <= 8'd1;
	end
	else begin
		case(sta_rw)
		4'd0:
			if(En_RW)
				sta_rw <= 4'd1;
		4'd1:begin																//��ʼ������
			rEn_SPI <= 1'b0;
			case(substp)
			4'd0:begin
				rCSN <= 1'b0;
				rEn_SPI <= 1'b1;
				rSBUF <= cmd;//д������
				if(cmd&`ADNSD3080_WRITE)
					delay1_cnt <= 8'd5;		
				else
					delay1_cnt <= 8'd75;									//Ԥװ��ʱʱ�� 75
				substp <= substp + 1'b1;
			end
			4'd1:
				if(SPI_RxDat_Rdy)begin								//�Խ������Ϊ������׼
					En_delay1 <= 1'b1;									//������ʱ
					if(cnt_rw>=size)begin								//��д�������
						cnt_rw <= 1'b0;
						delay1_cnt <= 8'd40;							//  50  50
						substp <= substp + 4'd3;					//
					end
					else 
						substp <= substp + 4'd1;						
				end
			4'd2:begin
				En_delay1 <= 1'b0;
				if(delay1_tup)
					substp <= substp + 4'd1;
			end
			4'd3:begin
				rEn_SPI <= 1'b1;
				if(cmd==(`ADNSD3080_WRITE|`ADNS3080_SROM_LOAD))
					rSBUF <= SROM_Dat;	 						//д��SROM
				else
					rSBUF <= wr_buf;	 							//д������
				cnt_rw <= cnt_rw +1'b1;
				if(cmd==(`ADNSD3080_WRITE|`ADNS3080_MOTION_BURST))							
					delay1_cnt <= 8'd0;									//����д����ֽڵ�MOT burst û�м��
				else
					delay1_cnt <= 8'd6;									//���ֽ�������д����Ϊ10us,��ȥдһ�ֽں�ʱ���Լ��5us
					
				substp <= 4'd1;
			end
			4'd4,4'd5,4'd6,4'd7,4'd8,4'd9,4'd10,4'd11,4'd12,4'd13:
				substp <= substp + 4'd1;								//��ʱ
			4'd14:begin
				En_delay1 <= 1'b0;
				rCSN <= 1'b1;														//С����ʱ����ǰ����
				substp <= substp + 4'd1;
			end
			4'd15:
				if(delay1_tup)begin
					substp <= 4'd0;
					RW_done <= 1'b1;
					sta_rw <= sta_rw + 1'b1;							//������һ������
				end
			endcase
		end
		4'd2:begin
			RW_done <= 1'b0;
			sta_rw <= 4'd0;
		end
		endcase
	end
	

//-------------���ն�ȡ����------------------
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		Rx_FIFO_WR_Req <= 1'b0;
		sta_rr <= 1'b0;
		ADNS_regdat <= 1'b0;
	end
	else case(sta_rr)
	2'd0:begin
		if(SPI_RxDat_Rdy)begin
			if(cnt_rw>=1)begin
				if(En_wFIFO)begin
					Rx_FIFO_WR_Req <= 1'b1;
					sta_rr <= 2'd1;
				end
				else
					ADNS_regdat = RBUF;
			end
		end
	end
	2'd1:begin
		Rx_FIFO_WR_Req <= 1'b0;
		sta_rr <= 2'd0;
	end
	endcase
	
assign RST = rRST;
assign CSN = rCSN;
assign SBUF = rSBUF;
assign En_SPI = rEn_SPI;
assign dat_out = ADNS_regdat;
assign sta_out = sta_3080;
assign Time_Mark = rTime_Mark;

endmodule


/**********************END OF FILE COPYRIGHT @2016************************/	
