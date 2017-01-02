/**********************DAMMSTANGER COPYRIGHT @2016************************
�������ƣ�MS5611_Driver_SPI
����������MS5611 SPI����
��	ע��PROM����16�ֽڵ����ݣ�ǰ2���ֽڣ�1��16bit�ֵ�ַ0xA0������Ϊ�����������ã���14���ֽ��ڳ�ʼ��������
				ѭ�����6�ֽڵĴ��������ݰ�����24bit���¶�+��24bit����ѹ���¶���ǰ������ΪδУ׼��ԭʼ����
��	 �ߣ�dammstanger
��	 �ڣ�20160819
*************************************************************************/	
module MS5611_Driver_SPI (
input  CLK,
input  RSTn,
input  En,
output CSN,
output En_SPI,
input  SPI_Busy_Flg,
input  SPI_RxDat_Rdy,
output [7:0]SBUF,
input  [7:0]RBUF,
input  Rx_FIFO_RD_Req,
output [7:0]Rx_FIFO_dat,
output Rx_FIFO_Full,
output Dat_Rdy_Sig,
output [3:0]Rx_Dat_Cnt,
output Time_Mark,
output [2:0]sta_out
);


/*********************************************************************************************************
	�����궨��--ADNS3080�ڲ��Ĵ���ָ��
*********************************************************************************************************/
`define RESET  													8'h1e
`define	CONV_D1_256   									8'h40	//-------uncompensated pressure--------------
`define	CONV_D1_512   									8'h42
`define	CONV_D1_1024   									8'h44
`define	CONV_D1_2048   									8'h46
`define	CONV_D1_4096   									8'h48
`define	CONV_D2_256   									8'h50	//------uncompensated temperature-------------
`define	CONV_D2_512   									8'h52
`define	CONV_D2_1024   									8'h54
`define	CONV_D2_2048   									8'h56
`define	CONV_D2_4096   									8'h58
`define ADC_READ   											8'h00	//
`define	PROM_READ												8'ha0	//��0xAE ����2һ��8��16bit��


parameter D1_RESOLUTION = `CONV_D1_4096;
parameter D2_RESOLUTION = `CONV_D2_4096;
parameter TPERIOD = 16'd10;

/***************Nmsѭ����ʱ��*******************/
wire vclk;
delayNms_cyc_module #(TPERIOD)delayNms_cyc_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk(vclk)
);


/***************us��ʱ��1*******************/
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

/***************us��ʱ��1*******************/
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
reg FIFO_clr;
reg Rx_Aclr;
reg Rx_FIFO_WR_Req;
wire Rx_Empty_Sig;
	

FIFO_8_16	FIFO_5611(
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


/****************��ȡ���ֲ���*********************/

reg [1:0]sta_FIFO;

/****************��д�Ĵ������̲���********************/
reg [3:0]sta_rw;
reg [3:0]substp;
reg [7:0]cmd;
reg [4:0]size;
reg [7:0]rSBUF;
reg rCSN;
reg rEn_SPI;
reg RW_done;					//��д������ɱ�־
reg [4:0]cnt_rw;
/****************��״̬��********************/
	 parameter 	CHK = 3'd0,
							INIT = 3'd1,
							IDLE = 3'd2,
							SEND = 3'd4,
							REST = 3'd5;
	 
	 reg rEnBuadcnt;
	 reg [2:0]sta_5611;
	 reg [3:0]stp;
	 reg En_RW;
	 reg first;
	 reg [4:0]cnt;
	 reg samp_puse;
	 reg rDat_Rdy;
	 reg rTime_Mark;
	 /****************************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_5611 <= REST;
		stp <= 1'b0;
		En_RW <= 1'b0;
		FIFO_clr <= 1'b0;
		first <= 1'b1;
		cnt <= 1'b0;
		samp_puse <= 1'b0;
		rDat_Rdy <= 1'b0;
		rTime_Mark <= 1'b0;
		cmd <= 1'b0;
		size <= 1'b0;
		En_delay2 <= 1'b0;
		delay2_cnt <= 16'd20;
	end 
	else begin
	En_delay2 <= 1'b0;	//�����źŸ�λ�ڴ�
	En_RW <= 1'b0;
	FIFO_clr <= 1'b0;
	rDat_Rdy <= 1'b0;
	rTime_Mark <= 1'b0;
	if(En)
		case(sta_5611)
		REST:begin
			case(stp)
			4'd0://----------------------------------------------
			if(first)begin
				En_RW <= 1'b1;
				first <= 1'b0;
				cmd <= `RESET;  size <= 5'd0; 
			end
			else if(RW_done)begin
				first <= 1'b1;
				En_delay2 <= 1'b1;
				delay2_cnt <= 16'd100;			//��ʱ100us
				stp <= stp + 1'b1;
			end		
			4'd1://----------------------------------------------
			if(delay2_tup)begin
				sta_5611 <= INIT;						//ÿ�θ�λ֮����Ҫ�ض�PROM
				FIFO_clr <= 1'b1;						//��PROM֮ǰ����FIFO
				cnt <= 5'd0;
				stp <= 1'b0;	
			end
			endcase
		end
		INIT:begin											
			if(cnt==5'd16)begin
				cnt <= 1'b0;
				rDat_Rdy <= 1'b1;						//PROM����׼����
				stp <= stp + 1'b1;
				sta_5611 <= IDLE;						
			end
			else if(first)begin
				En_RW <= 1'b1;
				first <= 1'b0;
				cmd <= `PROM_READ+cnt;  size <= 5'd2; 	//ͨ��cnt�ĵ�����������PROM����
			end
			else if(RW_done)begin
				first <= 1'b1;
				cnt <= cnt + 2'd2;
			end
		end
		IDLE:begin												/****************standby*****************/
			if(vclk)begin
				samp_puse <= ~samp_puse;				//�൱��1��Ƶvclk,����FIFO�������������Ͳɼ����ڶ�ȡ����
				sta_5611 <= SEND;
			end
			else
				sta_5611 <= IDLE;
		end
		SEND:begin												/****************���Ͳ���*********************/
			case(stp)
			4'd0:
				if(samp_puse)									
					stp <= stp +1'b1;						//��1��10ms����ѹ
				else
					stp <= stp +4'd3;
			4'd1://---------------------����ѹ-------------------------
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADC_READ;  size <= 5'd3; 
				end	
				else if(RW_done)begin
					first <= 1'b1;
					rDat_Rdy <= 1'b1;						//����׼����
					rTime_Mark <= 1'b1;
					stp <= stp + 4'd1;
				end	
			4'd2://---------------------�����¶�ת��--------------------
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= D2_RESOLUTION;  size <= 5'd0; 
				end	
				else if(RW_done)begin
					first <= 1'b1;
					stp <= 4'd0;
					sta_5611 <= IDLE;					
				end	
			4'd3://---------------------���¶�-------------------------
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					FIFO_clr <= 1'b1;									//һ�����ڵĿ�ʼ����֮ǰ����FIFO
					cmd <= `ADC_READ;  size <= 5'd3; 
				end	
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 4'd1;
				end	
			4'd4://---------------------������ѹת��--------------------
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= D1_RESOLUTION;  size <= 5'd0; 
				end	
				else if(RW_done)begin
					first <= 1'b1;
					stp <= 4'd0;
					sta_5611 <= IDLE;					
				end	
			endcase
		end
		endcase
	end
	


/*******************��д�ֽ�����*********************/
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
		En_delay1 <= 1'b0;												//�������źŸ�λ
		rEn_SPI <= 1'b0;
		case(sta_rw)
		4'd0:
			if(En_RW)
				sta_rw <= 4'd1;
		4'd1:begin																//��ʼ������
			case(substp)
			4'd0:begin
				rCSN <= 1'b0;
				rEn_SPI <= 1'b1;
				rSBUF <= cmd;//д������
				substp <= substp + 1'b1;
			end
			4'd1:
				substp <= substp + 1'b1;							//��ʱ
			4'd2:
				if(!SPI_Busy_Flg)begin								//�Է������Ϊ������׼
					if(cnt_rw>=size)begin								//��д�������
						cnt_rw <= 1'b0;
						En_delay1 <= 1'b1;								//������ʱ
						if(cmd==`RESET)
							delay1_cnt <= 16'd3000;						//**********************3000
						else
							delay1_cnt <= 8'd0;							//Ԥװ��ʱʱ�� 0
						substp <= substp + 4'd2;					//
					end
					else 
						substp <= substp + 4'd1;						
				end
			4'd3:begin
				rEn_SPI <= 1'b1;
				cnt_rw <= cnt_rw +1'b1;
				substp <= 4'd1;
			end
			4'd4:
				if(delay1_tup)begin
					rCSN <= 1'b1;				
					substp <= 4'd0;
					RW_done <= 1'b1;
					sta_rw <= sta_rw + 1'b1;						//������һ������
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
		sta_FIFO <= 1'b0;
		Rx_Aclr <= 1'b1;
	end
	else begin
	Rx_Aclr <= 1'b0;
	case(sta_FIFO)
	2'd0:begin
		if(FIFO_clr&&(!Rx_Empty_Sig))begin		// ���ڶ�ȡ�¶ȵ�֮ǰ���FIFO����֤FIFO���¶�->��ѹ ��˳��
			Rx_Aclr <= 1'b1;
			sta_FIFO <= sta_FIFO + 2'd2;	
		end	
		else if(SPI_RxDat_Rdy)
			if(cnt_rw>=1)begin					//ֻҪ�������ڵ���1����Ҫ����FIFO
				Rx_FIFO_WR_Req <= 1'b1;
				sta_FIFO <= 2'd1;
			end
		else 
			sta_FIFO <= 2'd0;
	end
	2'd1:begin
		Rx_FIFO_WR_Req <= 1'b0;
		sta_FIFO <= 2'd0;
	end
	2'd2:begin
		sta_FIFO <= 2'd0;
	end
	endcase
end
	
assign CSN = rCSN;
assign SBUF = rSBUF;
assign En_SPI = rEn_SPI;
assign sta_out = sta_5611;
assign Dat_Rdy_Sig = rDat_Rdy;
assign Time_Mark = rTime_Mark;

endmodule


/**********************END OF FILE COPYRIGHT @2016************************/	

