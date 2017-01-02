
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�������ƣ�SPI_2401_Driver
//����������SPI2401��������д24L01�Ĵ���
//��	 �ߣ�dammstanger
//��	 �ڣ�20160910
/*************************************************************************/	
module SPI_2401_Driver (
input  CLK,
input  RSTn,
input  En,
output CE,
output CSN,
input  IRQ,
input  [5:0]Tx_Dat_Num,
input  [7:0]Tx_Dat,
output [4:0]Tx_Dat_Addr,
output [7:0]SBUF,
input  [7:0]RBUF,
input  Rx_FIFO_RD_Req,
output [7:0]Rx_FIFO_dat,
output Rx_FIFO_Full,
input  SPI_RxDat_Rdy,
input  SPI_Busy_Flg,
output En_SPI,
output [2:0]sta_out,
output dbg_2401,
output dbg_2401_2,
output [3:0]sta_stp
);


/*********************************************************************************************************
	�����궨��--NRF24L01�ڲ��Ĵ���ָ��
*********************************************************************************************************/
`define NRF_READ_REG		8'h00  	// ���Ĵ���ָ��
`define NRF_WRITE_REG		8'h20 	// д�Ĵ���ָ��
`define R_RX_PL_WID   	8'h60
`define RD_RX_PLOAD     8'h61  	// ��ȡ��������ָ��
`define WR_TX_PLOAD     8'hA0  	// д��������ָ��
`define FLUSH_TX        8'hE1 	// ��ϴ���� FIFOָ��
`define FLUSH_RX        8'hE2  	// ��ϴ���� FIFOָ��
`define REUSE_TX_PL     8'hE3  	// �����ظ�װ������ָ��
`define NOP             8'hFF  	// ����


/*********************************************************************************************************
	�����궨��--NRF24L01(SPI)�ڲ��Ĵ�����ַ
*********************************************************************************************************/
`define CONFIG          8'h00  // �����շ�״̬��CRCУ��ģʽ�Լ��շ�״̬��Ӧ��ʽ
`define EN_AA           8'h01  // �Զ�Ӧ��������
`define EN_RXADDR       8'h02  // �����ŵ�����
`define SETUP_AW        8'h03  // �շ���ַ�������
`define SETUP_RETR      8'h04  // �Զ��ط���������
`define RF_CH           8'h05  // ����Ƶ������
`define RF_SETUP        8'h06  // �������ʡ����Ĺ�������
`define NRFRegSTATUS    8'h07  // ״̬�Ĵ���
`define OBSERVE_TX      8'h08  // ���ͼ�⹦��
`define CD              8'h09  // ��ַ���           
`define RX_ADDR_P0      8'h0A  // Ƶ��0�������ݵ�ַ
`define RX_ADDR_P1      8'h0B  // Ƶ��1�������ݵ�ַ
`define RX_ADDR_P2      8'h0C  // Ƶ��2�������ݵ�ַ
`define RX_ADDR_P3      8'h0D  // Ƶ��3�������ݵ�ַ
`define RX_ADDR_P4      8'h0E  // Ƶ��4�������ݵ�ַ
`define RX_ADDR_P5      8'h0F  // Ƶ��5�������ݵ�ַ
`define TX_ADDR         8'h10  // ���͵�ַ�Ĵ���
`define RX_PW_P0        8'h11  // ����Ƶ��0�������ݳ���
`define RX_PW_P1        8'h12  // ����Ƶ��1�������ݳ���
`define RX_PW_P2        8'h13  // ����Ƶ��2�������ݳ���
`define RX_PW_P3        8'h14  // ����Ƶ��3�������ݳ���
`define RX_PW_P4        8'h15  // ����Ƶ��4�������ݳ���
`define RX_PW_P5        8'h16  // ����Ƶ��5�������ݳ���
`define FIFO_STATUS     8'h17  // FIFOջ��ջ��״̬�Ĵ�������
//
///*********************************************************************************************************
//	�����궨��--NRF24L01����
//*********************************************************************************************************/
`define RX_DR				8'd6		//�жϱ�־
`define TX_DS				8'd5
`define MAX_RT			8'd4
`define MAX_TX  		8'h10  //�ﵽ����ʹ����ж�
`define TX_OK   		8'h20  //TX��������ж�
`define RX_OK   		8'h40  //���յ������ж�

`define MODEL_RX		8'd1			//��ͨ����
`define MODEL_TX		8'd2			//��ͨ����
`define MODEL_RX2		8'd3			//����ģʽ2,����˫����
`define MODEL_TX2		8'd4			//����ģʽ2,����˫����

`define RX_PLOAD_WIDTH  8'd32  	
`define TX_PLOAD_WIDTH  8'd32
`define ADR_WIDTH    8'd5 	 	


/*********************************************************************************************************
	��ʼ���Ĵ����ĳ�ֵ
*********************************************************************************************************/
`define NRF_ADDR_0 8'h34		//NRF��ַ
`define NRF_ADDR_1 8'h43
`define NRF_ADDR_2 8'h10
`define NRF_ADDR_3 8'h10
`define NRF_ADDR_4 8'h01

`define NRF_RF_CH  8'd40

//================ѭ������==========================
wire vclk;
delayNms_cyc_module #(16'd50)delayNms_cyc_module_2401(		//50ms
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk( vclk )
);

//***************��ʱ**************************
reg En_delay;
reg [15:0]delay_cnt;
wire dy_timup;

delayNus_module delayNus_module_2401(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_delay),
	.Nus(delay_cnt),
	.timeup(dy_timup)
);

//=========================================
wire Sig_Init_Rdy;
wire H2L_Sig_IRQ;
//wire L2H_Sig_IRQ;
Sig_Edge_Detect IRQ_Edge(				//�жϵĸ�����Ͽ������õ�ƽ���ж��ж�
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Sig_Init_Rdy), 
	.Pin_In( IRQ ), 
	.H2L_Sig( H2L_Sig_IRQ )
//	.L2H_Sig( L2H_Sig_IRQ )
);	
	

/******************����FIFO***********************/

parameter Rx_Aclr=1'b0;
reg Rx_FIFO_WR_Req;
wire Rx_Empty_Sig;

FIFO	FIFO_Rx(
	.clock ( CLK ),
	.aclr (Rx_Aclr),
	.data ( RBUF ),
	.rdreq ( Rx_FIFO_RD_Req ),
	.wrreq ( Rx_FIFO_WR_Req ),
	.empty ( Rx_Empty_Sig ),
	.full ( Rx_FIFO_Full ),
	.q ( Rx_FIFO_dat )
	);

/****************DRAM��ȡ���ֲ���*********************/
reg En_RDRAM;								//ʹ�ܵ�ַ��ַ����
/****************SPI��ȡ���ֲ���*********************/

reg [1:0]sta_rr;
reg [7:0]nrf_sta;


/****************��д�Ĵ������̲���********************/
reg [3:0]sta_rw;
reg [3:0]substp;
reg [7:0]cmd;
reg [8:0]size;
reg [7:0]wr_buf[31:0];
reg [7:0]rSBUF;
reg rCSN;
reg rEn_SPI;
reg RW_done;					//��д������ɱ�־
reg [8:0]cnt_rw;
/****************��״̬��********************/
	 parameter 	INIT = 3'd0,
							IDLE = 3'd1,
							REV  = 3'd2,
							SEND = 3'd3,
							INTR = 3'd4,
							LOAD = 3'd5;
	 
	 reg rEnBuadcnt;
	 reg rCE;
	 reg [2:0]sta_2401;
	 reg [2:0]sta_2401_lst;
	 reg [3:0]stp;
	 reg [5:0]num;
	 reg En_RW;
	 reg first;
	 reg En_wFIFO;
	 reg [7:0]stime_limt_cnt;
	 reg dbg,dbg2;
	 /****************************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_2401 <= INIT;
		sta_2401_lst <= INIT;
		stp <= 1'b0;
		rCE <= 1'b0;
		En_RW <= 1'b0;
		En_RDRAM <= 1'b0;
		En_wFIFO <= 1'b0;
		first <= 1'b1;
		cmd <= 1'b0;
		size <= 1'b0;
		num <= 1'b0;
		stime_limt_cnt <= 1'b0;
		//==��ʱ
		En_delay <= 1'b0;
		delay_cnt <= 20;
		dbg <= 1'b0;
		dbg2 <= 1'b0;
		wr_buf[0] <= `NRF_ADDR_0;
		wr_buf[1] <= `NRF_ADDR_1;
		wr_buf[2] <= `NRF_ADDR_2;
		wr_buf[3] <= `NRF_ADDR_3;
		wr_buf[4] <= `NRF_ADDR_4;
		wr_buf[6] <= 8'h66;
		wr_buf[7] <= 8'h77;
		wr_buf[8] <= 8'h88;
	end 
	else begin
		case(sta_2401)
		INIT:begin
			if(En)begin
				En_RW <= 1'b0;
				rCE <= 1'b0;
				if(sta_2401_lst==IDLE)
					dbg <= 1'b1;
					
				case(stp)
				4'd0:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`RX_ADDR_P0;  size<=`ADR_WIDTH; //Rx�ڵ��ַ 
						wr_buf[0] <= `NRF_ADDR_0;
						wr_buf[1] <= `NRF_ADDR_1;
						wr_buf[2] <= `NRF_ADDR_2;
						wr_buf[3] <= `NRF_ADDR_3;
						wr_buf[4] <= `NRF_ADDR_4;	
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd1:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`TX_ADDR;  size<=`ADR_WIDTH; 	//дTX�ڵ��ַ 
						wr_buf[0] <= `NRF_ADDR_0;
						wr_buf[1] <= `NRF_ADDR_1;
						wr_buf[2] <= `NRF_ADDR_2;
						wr_buf[3] <= `NRF_ADDR_3;
						wr_buf[4] <= `NRF_ADDR_4;	
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
						cmd <= `NRF_WRITE_REG|`EN_AA;  size<= 1'b1; 		//��ֹ����ͨ�����Զ�Ӧ�� 
						wr_buf[0] <= 8'h00;
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
						cmd <= `NRF_WRITE_REG|`EN_RXADDR;  size<=1'b1; 	//ʹ��ͨ��0�Ľ��յ�ַ 
						wr_buf[0] <= 8'h01;
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd4:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`SETUP_RETR;  size<=1'b1; //��ֹ�Զ��ط�
						wr_buf[0] <= 8'h00;
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd5:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`RF_CH;  size<=1'b1; //����RFͨ��ΪCHANAL
						wr_buf[0] <= `NRF_RF_CH;
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
						cmd <= `NRF_WRITE_REG|`RF_SETUP;  size<=1'b1; 
						wr_buf[0] <= 8'h0f;													//����TX�������,0db����,2Mbps,���������濪��
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd7:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`NRFRegSTATUS;  size<=1'b1; 
						wr_buf[0] <= `MAX_TX|`TX_OK|`RX_OK;					//���ж�
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd8:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `FLUSH_RX;  size<=1'b1; 		//��� ���� FIFO
						wr_buf[0] <= 8'hff;
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd9:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `FLUSH_TX;  size<=1'b1; 		//��� ���� FIFO
						wr_buf[0] <= 8'hff;
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
						cmd <= `NRF_WRITE_REG|`RX_PW_P0;  size<=1'b1; 
						wr_buf[0] <= `RX_PLOAD_WIDTH;								//ѡ��ͨ��0����Ч���ݿ�� 
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				end
				4'd11:begin
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`CONFIG;  size<=1'b1; 
						wr_buf[0] <= 8'h1f;												 // IRQ�շ�����жϿ���,16λCRC,������
					end
					else if(RW_done)begin
						first <= 1'b1;
						sta_2401 <= IDLE;
						sta_2401_lst<= sta_2401;
						stp <= 1'b0;
					end
				end
				endcase
			end
		end
		IDLE:begin									/****************standby*****************/
		
			En_RW <= 1'b0;				//���жϡ����͡����ղ���ʱ����2401���ڽ���ģʽ
			if(H2L_Sig_IRQ)begin					//���ж�
				sta_2401 <= INTR;
//				dbg <= 1'b0;
				sta_2401_lst <= sta_2401;
			end
			else if(sta_2401_lst==INTR&En)begin 		
				case(stp)
				4'd0: 
					if(nrf_sta&`TX_OK)begin													//������ɣ��л�������ģʽ��ע����ʱ���ͻ᲻�ɹ�������Ҫ��ʱ����
						stime_limt_cnt <= 1'b0;	//
						stp <= stp + 1'b1;
					end
					else if(nrf_sta&`RX_OK)begin										//���յ����ݣ����н��ղ���
						sta_2401 <= REV;
						sta_2401_lst <= sta_2401;
					end
					else begin
						sta_2401_lst <= IDLE;													//�������󴥷��������жϣ�ֻ����sta_2401_lst
					end
				4'd1:
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `FLUSH_TX;  size<=1'b1; 								//��� ���� FIFO
						wr_buf[0] <= 8'hff;
					end
					else if(RW_done)begin
						first <= 1'b1;
						stp <= stp + 1'b1;
					end
				4'd2:
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `NRF_WRITE_REG|`CONFIG;  size<=1'b1; 
						wr_buf[0] <= 8'h1f;								 						// ������ IRQ�շ�����жϿ���,16λCRC,
					end
					else if(RW_done)begin
					first <= 1'b1;
					stp <= 1'b0;
					sta_2401_lst <= sta_2401;
				end
				endcase
			end	
			else if(vclk&En)begin
				if(stime_limt_cnt>1'b1)						//�ϴη��ͻ�δ�ɹ�
					stime_limt_cnt <= stime_limt_cnt -1'b1;
				else if(stime_limt_cnt==1'b1)begin
					stime_limt_cnt <= 8'd0;					//������˵�����ͳ�ʱ
					sta_2401 <= INIT;								//���³�ʼ��
				end
				else begin				//������ʱ��if(Tx_Dat_Num>0)
					sta_2401 <= SEND;
					sta_2401_lst <= sta_2401;
				end
			end
		end

		REV:begin										/****************���ղ���*********************/
			En_RW <= 1'b0;
			rCE <= 1'b0;
			case(stp)
			4'd0:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					En_wFIFO <= 1'b1;
					cmd <= `RD_RX_PLOAD;  size<=`RX_PLOAD_WIDTH; 
					end
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end	
			end	
			4'd1:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					En_wFIFO <= 1'b0;										//��ֹд��FIFO
					cmd <= `FLUSH_RX;  size<=1'b1; 
					wr_buf[0] <= 8'hff;								  // IRQ������жϿ���,16λCRC,������
				end
				else if(RW_done)begin
					first <= 1'b1;
					sta_2401 <= IDLE;
					sta_2401_lst <= sta_2401;
					stp <= 1'b0;
				end	
			end
			endcase
		end
		LOAD:begin
			En_RDRAM <= 1'b0;						//�����źŸ�λ
			if(Tx_Dat_Num==1)begin			//ֻ��һ���ֽ�
				wr_buf[0] <= Tx_Dat;
				sta_2401 <= SEND;
				sta_2401_lst <= sta_2401;	
			end
			else if(Tx_Dat_Num>1)begin
				case(stp)
				4'd0:begin
					En_RDRAM <= 1'b1;
					stp <= stp + 1'b1;
				end
				4'd1:
					stp <= stp + 1'b1;
				4'd2:
					if(num<Tx_Dat_Num)begin
						num <= num + 1'b1;
						wr_buf[num] <= Tx_Dat;
					end
					else begin
						num <= 1'b0;
						stp <= 4'd2;			//ֱ�ӵ�3��
						sta_2401 <= SEND;
						sta_2401_lst <= sta_2401;
					end
				endcase
			end
		end
		SEND:begin												/****************���Ͳ���*********************/
			En_RW <= 1'b0;						//�������źŸ�λ
			En_delay 	<= 1'b0;
			case(stp)
			4'd0:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `NRF_WRITE_REG|`CONFIG;  size<=1'b1; 
					wr_buf[0] <= 8'h1e;								 // IRQ������жϿ���,16λCRC,������
				end
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end	
			end
			4'd1:begin
				stp <= 1'b0;
				sta_2401 <= LOAD;									//װ��ֵ
				sta_2401_lst <= sta_2401;				
			end
			4'd2:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `WR_TX_PLOAD;  size <= `TX_PLOAD_WIDTH; 
				end
				else if(RW_done)begin
					first <= 1'b1;
					rCE <= 1'b1;										//����CEʹ�ܷ���		
					
					delay_cnt <= 16'd50;						//====������ʱ����֤����>10us========
					En_delay 	<= 1'b1;
					stp <= stp + 1'b1;
				end	
			end
			4'd3:begin
				if(dy_timup)begin
					rCE <= 1'b1;										//����CE�������	
					stime_limt_cnt <= 8'd100;				//������ʱ������������������װ��
//					dbg <= 1'b1;
					sta_2401 <= IDLE;
					sta_2401_lst <= sta_2401;
					stp <= 1'b0;
				end
			end
			endcase
		end
		INTR:begin						/****************�жϴ���*************Flg_sdone********/
			En_RW <= 1'b0;			//������дģ�飬һ��Ҫ��
		  rCE <= 1'b0;
			if(first)begin
				first <= 1'b0;
				En_RW <= 1'b1;
				cmd <= `NRF_WRITE_REG|`NRFRegSTATUS;  size<=1'b1; 
				wr_buf[0] <= `MAX_TX|`TX_OK|`RX_OK;					//���ж�
			end
			else if(RW_done)begin
				first <= 1'b1;
				sta_2401 <= IDLE;
				sta_2401_lst <= sta_2401;
			end	
		end
		endcase
	end
	
/*******************��DRAM���ֽ�����*********************/
reg [4:0]rTx_Dat_Addr;
reg [1:0]sta_rdram;
always @ ( negedge CLK or negedge RSTn )
	if( !RSTn )begin
		rTx_Dat_Addr <= 1'b0;
		sta_rdram <= 1'b0;
	end
	else 
		case(sta_rdram)
		1'b0:
			if(En_RDRAM)begin
				rTx_Dat_Addr <= rTx_Dat_Addr + 1'b1;
				sta_rdram <= sta_rdram + 1'b1;
			end
			else
				sta_rdram <= 1'b0;
		1'b1:
			if(rTx_Dat_Addr<Tx_Dat_Num-1)
				rTx_Dat_Addr <= rTx_Dat_Addr + 1'b1;
			else begin
				rTx_Dat_Addr <= 1'b0;
				sta_rdram <= 1'b0;
			end
		endcase
		

/*******************��д�ֽ�����*********************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_rw 	<= 4'd0;
		substp 	<= 1'b0;
		rCSN 		<= 1'b1;
		rEn_SPI 	<= 1'b0;
		cnt_rw 	<= 4'd0;
		rSBUF 	<= 1'b0;
		RW_done <= 1'b0;
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
				if(!SPI_Busy_Flg)begin
					rCSN <= 1'b0;
					rEn_SPI <= 1'b1;
					rSBUF <= cmd;//д������
					substp <= substp + 1'b1;
				end
			end
			4'd1,4'd2:
				substp <= substp + 1'b1;							//��ʱ
			4'd3:begin
				if(!SPI_Busy_Flg)begin
					if(cnt_rw>=size)begin
						rCSN <= 1'b1;
						cnt_rw <= 1'b0;
						substp <= 1'b0;
						RW_done <= 1'b1;
						sta_rw <= 4'd2;									//������һ������
					end
					else begin
						rEn_SPI <= 1'b1;
						rSBUF <= wr_buf[cnt_rw];	 //д������
						cnt_rw <= cnt_rw +1'b1;
						substp <= substp + 1'b1;
					end
				end
			end
			4'd4:
				substp <= substp + 1'b1;							//��ʱ
			4'd5:begin
				substp <= 4'd3;
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
		nrf_sta <= 1'b0;
	end
	else case(sta_rr)
	2'd0:begin
		if(SPI_RxDat_Rdy)begin
			if(cnt_rw>=1)begin
				if(En_wFIFO)begin
					Rx_FIFO_WR_Req <= 1'b1;
					sta_rr <= 2'd1;
				end
			end
			else 
				nrf_sta <= RBUF;					//��������24L01ʱ��0x07��״̬�Ĵ���ֵͬʱ�Ƴ����ڴ˽���
		end
	end
	2'd1:begin
		Rx_FIFO_WR_Req <= 1'b0;
		sta_rr <= 2'd0;
	end
	endcase


assign Tx_Dat_Addr = rTx_Dat_Addr;
assign CSN = rCSN;
assign SBUF = rSBUF;
assign CE = rCE;
assign En_SPI = rEn_SPI;
assign sta_out = sta_2401;
assign sta_stp = stp;
assign dbg_2401 = dbg;
assign dbg_2401_2 = dbg2;
endmodule


/**********************END OF FILE COPYRIGHT @2016************************/	