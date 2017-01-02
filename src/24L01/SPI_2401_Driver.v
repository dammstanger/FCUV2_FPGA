
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：SPI_2401_Driver
//工程描述：SPI2401驱动，读写24L01寄存器
//作	 者：dammstanger
//日	 期：20160910
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
	常量宏定义--NRF24L01内部寄存器指令
*********************************************************************************************************/
`define NRF_READ_REG		8'h00  	// 读寄存器指令
`define NRF_WRITE_REG		8'h20 	// 写寄存器指令
`define R_RX_PL_WID   	8'h60
`define RD_RX_PLOAD     8'h61  	// 读取接收数据指令
`define WR_TX_PLOAD     8'hA0  	// 写待发数据指令
`define FLUSH_TX        8'hE1 	// 冲洗发送 FIFO指令
`define FLUSH_RX        8'hE2  	// 冲洗接收 FIFO指令
`define REUSE_TX_PL     8'hE3  	// 定义重复装载数据指令
`define NOP             8'hFF  	// 保留


/*********************************************************************************************************
	常量宏定义--NRF24L01(SPI)内部寄存器地址
*********************************************************************************************************/
`define CONFIG          8'h00  // 配置收发状态，CRC校验模式以及收发状态响应方式
`define EN_AA           8'h01  // 自动应答功能设置
`define EN_RXADDR       8'h02  // 可用信道设置
`define SETUP_AW        8'h03  // 收发地址宽度设置
`define SETUP_RETR      8'h04  // 自动重发功能设置
`define RF_CH           8'h05  // 工作频率设置
`define RF_SETUP        8'h06  // 发射速率、功耗功能设置
`define NRFRegSTATUS    8'h07  // 状态寄存器
`define OBSERVE_TX      8'h08  // 发送监测功能
`define CD              8'h09  // 地址检测           
`define RX_ADDR_P0      8'h0A  // 频道0接收数据地址
`define RX_ADDR_P1      8'h0B  // 频道1接收数据地址
`define RX_ADDR_P2      8'h0C  // 频道2接收数据地址
`define RX_ADDR_P3      8'h0D  // 频道3接收数据地址
`define RX_ADDR_P4      8'h0E  // 频道4接收数据地址
`define RX_ADDR_P5      8'h0F  // 频道5接收数据地址
`define TX_ADDR         8'h10  // 发送地址寄存器
`define RX_PW_P0        8'h11  // 接收频道0接收数据长度
`define RX_PW_P1        8'h12  // 接收频道1接收数据长度
`define RX_PW_P2        8'h13  // 接收频道2接收数据长度
`define RX_PW_P3        8'h14  // 接收频道3接收数据长度
`define RX_PW_P4        8'h15  // 接收频道4接收数据长度
`define RX_PW_P5        8'h16  // 接收频道5接收数据长度
`define FIFO_STATUS     8'h17  // FIFO栈入栈出状态寄存器设置
//
///*********************************************************************************************************
//	常量宏定义--NRF24L01操作
//*********************************************************************************************************/
`define RX_DR				8'd6		//中断标志
`define TX_DS				8'd5
`define MAX_RT			8'd4
`define MAX_TX  		8'h10  //达到最大发送次数中断
`define TX_OK   		8'h20  //TX发送完成中断
`define RX_OK   		8'h40  //接收到数据中断

`define MODEL_RX		8'd1			//普通接收
`define MODEL_TX		8'd2			//普通发送
`define MODEL_RX2		8'd3			//接收模式2,用于双向传输
`define MODEL_TX2		8'd4			//发送模式2,用于双向传输

`define RX_PLOAD_WIDTH  8'd32  	
`define TX_PLOAD_WIDTH  8'd32
`define ADR_WIDTH    8'd5 	 	


/*********************************************************************************************************
	初始化寄存器的常值
*********************************************************************************************************/
`define NRF_ADDR_0 8'h34		//NRF地址
`define NRF_ADDR_1 8'h43
`define NRF_ADDR_2 8'h10
`define NRF_ADDR_3 8'h10
`define NRF_ADDR_4 8'h01

`define NRF_RF_CH  8'd40

//================循环脉冲==========================
wire vclk;
delayNms_cyc_module #(16'd50)delayNms_cyc_module_2401(		//50ms
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk( vclk )
);

//***************延时**************************
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
Sig_Edge_Detect IRQ_Edge(				//中断的负脉冲较宽，不能用电平来判断中断
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Sig_Init_Rdy), 
	.Pin_In( IRQ ), 
	.H2L_Sig( H2L_Sig_IRQ )
//	.L2H_Sig( L2H_Sig_IRQ )
);	
	

/******************接收FIFO***********************/

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

/****************DRAM读取部分参数*********************/
reg En_RDRAM;								//使能地址地址递增
/****************SPI读取部分参数*********************/

reg [1:0]sta_rr;
reg [7:0]nrf_sta;


/****************读写寄存器流程参数********************/
reg [3:0]sta_rw;
reg [3:0]substp;
reg [7:0]cmd;
reg [8:0]size;
reg [7:0]wr_buf[31:0];
reg [7:0]rSBUF;
reg rCSN;
reg rEn_SPI;
reg RW_done;					//读写任务完成标志
reg [8:0]cnt_rw;
/****************总状态机********************/
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
		//==延时
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
						cmd <= `NRF_WRITE_REG|`RX_ADDR_P0;  size<=`ADR_WIDTH; //Rx节点地址 
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
						cmd <= `NRF_WRITE_REG|`TX_ADDR;  size<=`ADR_WIDTH; 	//写TX节点地址 
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
						cmd <= `NRF_WRITE_REG|`EN_AA;  size<= 1'b1; 		//禁止所有通道的自动应答 
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
						cmd <= `NRF_WRITE_REG|`EN_RXADDR;  size<=1'b1; 	//使能通道0的接收地址 
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
						cmd <= `NRF_WRITE_REG|`SETUP_RETR;  size<=1'b1; //禁止自动重发
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
						cmd <= `NRF_WRITE_REG|`RF_CH;  size<=1'b1; //设置RF通道为CHANAL
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
						wr_buf[0] <= 8'h0f;													//设置TX发射参数,0db增益,2Mbps,低噪声增益开启
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
						wr_buf[0] <= `MAX_TX|`TX_OK|`RX_OK;					//清中断
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
						cmd <= `FLUSH_RX;  size<=1'b1; 		//清空 接收 FIFO
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
						cmd <= `FLUSH_TX;  size<=1'b1; 		//清空 发送 FIFO
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
						wr_buf[0] <= `RX_PLOAD_WIDTH;								//选择通道0的有效数据宽度 
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
						wr_buf[0] <= 8'h1f;												 // IRQ收发完成中断开启,16位CRC,主发送
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
		
			En_RW <= 1'b0;				//无中断、发送、接收操作时，将2401置于接收模式
			if(H2L_Sig_IRQ)begin					//有中断
				sta_2401 <= INTR;
//				dbg <= 1'b0;
				sta_2401_lst <= sta_2401;
			end
			else if(sta_2401_lst==INTR&En)begin 		
				case(stp)
				4'd0: 
					if(nrf_sta&`TX_OK)begin													//发送完成，切换到接收模式，注意有时候发送会不成功，就需要超时处理
						stime_limt_cnt <= 1'b0;	//
						stp <= stp + 1'b1;
					end
					else if(nrf_sta&`RX_OK)begin										//接收到数据，进行接收操作
						sta_2401 <= REV;
						sta_2401_lst <= sta_2401;
					end
					else begin
						sta_2401_lst <= IDLE;													//可能是误触发或其他中断，只更新sta_2401_lst
					end
				4'd1:
					if(first)begin
						first <= 1'b0;
						En_RW <= 1'b1;
						cmd <= `FLUSH_TX;  size<=1'b1; 								//清空 发送 FIFO
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
						wr_buf[0] <= 8'h1f;								 						// 主接收 IRQ收发完成中断开启,16位CRC,
					end
					else if(RW_done)begin
					first <= 1'b1;
					stp <= 1'b0;
					sta_2401_lst <= sta_2401;
				end
				endcase
			end	
			else if(vclk&En)begin
				if(stime_limt_cnt>1'b1)						//上次发送还未成功
					stime_limt_cnt <= stime_limt_cnt -1'b1;
				else if(stime_limt_cnt==1'b1)begin
					stime_limt_cnt <= 8'd0;					//到这里说明发送超时
					sta_2401 <= INIT;								//重新初始化
				end
				else begin				//正常定时到if(Tx_Dat_Num>0)
					sta_2401 <= SEND;
					sta_2401_lst <= sta_2401;
				end
			end
		end

		REV:begin										/****************接收操作*********************/
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
					En_wFIFO <= 1'b0;										//禁止写入FIFO
					cmd <= `FLUSH_RX;  size<=1'b1; 
					wr_buf[0] <= 8'hff;								  // IRQ收完成中断开启,16位CRC,主发送
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
			En_RDRAM <= 1'b0;						//脉冲信号复位
			if(Tx_Dat_Num==1)begin			//只有一个字节
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
						stp <= 4'd2;			//直接到3步
						sta_2401 <= SEND;
						sta_2401_lst <= sta_2401;
					end
				endcase
			end
		end
		SEND:begin												/****************发送操作*********************/
			En_RW <= 1'b0;						//脉冲型信号复位
			En_delay 	<= 1'b0;
			case(stp)
			4'd0:begin
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `NRF_WRITE_REG|`CONFIG;  size<=1'b1; 
					wr_buf[0] <= 8'h1e;								 // IRQ收完成中断开启,16位CRC,主发送
				end
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 1'b1;
				end	
			end
			4'd1:begin
				stp <= 1'b0;
				sta_2401 <= LOAD;									//装载值
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
					rCE <= 1'b1;										//拉高CE使能发送		
					
					delay_cnt <= 16'd50;						//====加入延时，保证脉宽>10us========
					En_delay 	<= 1'b1;
					stp <= stp + 1'b1;
				end	
			end
			4'd3:begin
				if(dy_timup)begin
					rCE <= 1'b1;										//拉低CE完成脉冲	
					stime_limt_cnt <= 8'd100;				//发送限时计数器，启动发送重装，
//					dbg <= 1'b1;
					sta_2401 <= IDLE;
					sta_2401_lst <= sta_2401;
					stp <= 1'b0;
				end
			end
			endcase
		end
		INTR:begin						/****************中断处理*************Flg_sdone********/
			En_RW <= 1'b0;			//启动读写模块，一定要有
		  rCE <= 1'b0;
			if(first)begin
				first <= 1'b0;
				En_RW <= 1'b1;
				cmd <= `NRF_WRITE_REG|`NRFRegSTATUS;  size<=1'b1; 
				wr_buf[0] <= `MAX_TX|`TX_OK|`RX_OK;					//清中断
			end
			else if(RW_done)begin
				first <= 1'b1;
				sta_2401 <= IDLE;
				sta_2401_lst <= sta_2401;
			end	
		end
		endcase
	end
	
/*******************从DRAM读字节流程*********************/
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
		

/*******************读写字节流程*********************/
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
		4'd1:begin																//初始化接收
			rEn_SPI <= 1'b0;
			case(substp)
			4'd0:begin
				if(!SPI_Busy_Flg)begin
					rCSN <= 1'b0;
					rEn_SPI <= 1'b1;
					rSBUF <= cmd;//写入命令
					substp <= substp + 1'b1;
				end
			end
			4'd1,4'd2:
				substp <= substp + 1'b1;							//延时
			4'd3:begin
				if(!SPI_Busy_Flg)begin
					if(cnt_rw>=size)begin
						rCSN <= 1'b1;
						cnt_rw <= 1'b0;
						substp <= 1'b0;
						RW_done <= 1'b1;
						sta_rw <= 4'd2;									//进入下一个命令
					end
					else begin
						rEn_SPI <= 1'b1;
						rSBUF <= wr_buf[cnt_rw];	 //写入数据
						cnt_rw <= cnt_rw +1'b1;
						substp <= substp + 1'b1;
					end
				end
			end
			4'd4:
				substp <= substp + 1'b1;							//延时
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
	

//-------------接收读取机制------------------
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
				nrf_sta <= RBUF;					//命令移入24L01时，0x07的状态寄存器值同时移出，在此接收
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