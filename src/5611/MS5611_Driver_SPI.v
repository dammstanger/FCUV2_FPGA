/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：MS5611_Driver_SPI
工程描述：MS5611 SPI驱动
备	注：PROM中有16字节的数据，前2个字节（1个16bit字地址0xA0）数据为厂商数据无用，后14个字节在初始化读出。
				循环输出6字节的传感器数据包：（24bit）温度+（24bit）气压，温度在前，数据为未校准的原始数据
作	 者：dammstanger
日	 期：20160819
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
	常量宏定义--ADNS3080内部寄存器指令
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
`define	PROM_READ												8'ha0	//到0xAE 步进2一共8个16bit字


parameter D1_RESOLUTION = `CONV_D1_4096;
parameter D2_RESOLUTION = `CONV_D2_4096;
parameter TPERIOD = 16'd10;

/***************Nms循环计时器*******************/
wire vclk;
delayNms_cyc_module #(TPERIOD)delayNms_cyc_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk(vclk)
);


/***************us定时器1*******************/
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

/***************us定时器1*******************/
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

/******************接收FIFO***********************/
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


/****************读取部分参数*********************/

reg [1:0]sta_FIFO;

/****************读写寄存器流程参数********************/
reg [3:0]sta_rw;
reg [3:0]substp;
reg [7:0]cmd;
reg [4:0]size;
reg [7:0]rSBUF;
reg rCSN;
reg rEn_SPI;
reg RW_done;					//读写任务完成标志
reg [4:0]cnt_rw;
/****************总状态机********************/
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
	En_delay2 <= 1'b0;	//脉冲信号复位在此
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
				delay2_cnt <= 16'd100;			//延时100us
				stp <= stp + 1'b1;
			end		
			4'd1://----------------------------------------------
			if(delay2_tup)begin
				sta_5611 <= INIT;						//每次复位之后都需要重读PROM
				FIFO_clr <= 1'b1;						//读PROM之前先清FIFO
				cnt <= 5'd0;
				stp <= 1'b0;	
			end
			endcase
		end
		INIT:begin											
			if(cnt==5'd16)begin
				cnt <= 1'b0;
				rDat_Rdy <= 1'b1;						//PROM数据准备好
				stp <= stp + 1'b1;
				sta_5611 <= IDLE;						
			end
			else if(first)begin
				En_RW <= 1'b1;
				first <= 1'b0;
				cmd <= `PROM_READ+cnt;  size <= 5'd2; 	//通过cnt的递增连续读出PROM数据
			end
			else if(RW_done)begin
				first <= 1'b1;
				cnt <= cnt + 2'd2;
			end
		end
		IDLE:begin												/****************standby*****************/
			if(vclk)begin
				samp_puse <= ~samp_puse;				//相当于1分频vclk,用于FIFO的周期性清理，和采集周期读取控制
				sta_5611 <= SEND;
			end
			else
				sta_5611 <= IDLE;
		end
		SEND:begin												/****************发送操作*********************/
			case(stp)
			4'd0:
				if(samp_puse)									
					stp <= stp +1'b1;						//第1个10ms读气压
				else
					stp <= stp +4'd3;
			4'd1://---------------------读气压-------------------------
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					cmd <= `ADC_READ;  size <= 5'd3; 
				end	
				else if(RW_done)begin
					first <= 1'b1;
					rDat_Rdy <= 1'b1;						//数据准备好
					rTime_Mark <= 1'b1;
					stp <= stp + 4'd1;
				end	
			4'd2://---------------------启动温度转换--------------------
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
			4'd3://---------------------读温度-------------------------
				if(first)begin
					first <= 1'b0;
					En_RW <= 1'b1;
					FIFO_clr <= 1'b1;									//一个周期的开始，读之前先清FIFO
					cmd <= `ADC_READ;  size <= 5'd3; 
				end	
				else if(RW_done)begin
					first <= 1'b1;
					stp <= stp + 4'd1;
				end	
			4'd4://---------------------启动气压转换--------------------
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
	


/*******************读写字节流程*********************/
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
		En_delay1 <= 1'b0;												//触发型信号复位
		rEn_SPI <= 1'b0;
		case(sta_rw)
		4'd0:
			if(En_RW)
				sta_rw <= 4'd1;
		4'd1:begin																//初始化接收
			case(substp)
			4'd0:begin
				rCSN <= 1'b0;
				rEn_SPI <= 1'b1;
				rSBUF <= cmd;//写入命令
				substp <= substp + 1'b1;
			end
			4'd1:
				substp <= substp + 1'b1;							//延时
			4'd2:
				if(!SPI_Busy_Flg)begin								//以发送完毕为结束标准
					if(cnt_rw>=size)begin								//读写任务完成
						cnt_rw <= 1'b0;
						En_delay1 <= 1'b1;								//启动延时
						if(cmd==`RESET)
							delay1_cnt <= 16'd3000;						//**********************3000
						else
							delay1_cnt <= 8'd0;							//预装延时时间 0
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
					sta_rw <= sta_rw + 1'b1;						//进入下一个命令
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
		sta_FIFO <= 1'b0;
		Rx_Aclr <= 1'b1;
	end
	else begin
	Rx_Aclr <= 1'b0;
	case(sta_FIFO)
	2'd0:begin
		if(FIFO_clr&&(!Rx_Empty_Sig))begin		// 即在读取温度的之前清除FIFO，保证FIFO：温度->气压 的顺序
			Rx_Aclr <= 1'b1;
			sta_FIFO <= sta_FIFO + 2'd2;	
		end	
		else if(SPI_RxDat_Rdy)
			if(cnt_rw>=1)begin					//只要读数大于等于1都需要存入FIFO
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

