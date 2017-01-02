/**********************DAMMSTANGER COPYRIGHT @2016************************
工程名称：HC_SR04_Driver
工程描述：HC_SR04的驱动 
作	 者：dammstanger
日	 期：20160820
*************************************************************************/	
module HC_SR04_Driver (
input CLK,
input RSTn,
input  En,
output TRIG,
inout  ECHO,
output Dat_Rdy_Sig,
output [15:0]Dist_mm,
output Time_Mark,
output [2:0]STA
);

/*********************************************************************************************************
	常量宏定义--9150设备地址
*********************************************************************************************************/
parameter TSAMP	= 16'd100;			//测量周期

wire [15:0]Time_us_dual;
reg [15:0]Time_us;
reg [23:0]rDist_mm;
//***************延时**************************
reg En_delay;
reg [15:0]delay_cnt;
wire dy_timup;

delayNus_module delayNus_module_sr04(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En_delay),
	.Nus(delay_cnt),
	.timeup(dy_timup)
);

//***************循环脉冲**************************
wire vclk;
delayNms_cyc_module #(TSAMP)delayNms_sr04(				//100ms一个脉冲
	.CLK( CLK ),
	.RSTn( RSTn ),
	.vclk( vclk )	
);


//***********************************************
reg En_cnt;
wire OverFlow;
Time_us_16b Time_us_16b_sr04( 
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En( En_cnt ), 
	.Nus( Time_us_dual ), 
	.OVERFLW( OverFlow )
);


//******************信号边缘检测****************
wire H2L_Sig;
wire L2H_Sig;
wire Edge_Detect_Rdy;
Sig_Edge_Detect Sig_Edge_Detect_TRIG(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Edge_Detect_Rdy),
	.Pin_In(ECHO), 									
	.H2L_Sig(H2L_Sig), 
	.L2H_Sig(L2H_Sig)	
);


//**************************************
wire [23:0]Dist_x100;
Mult_16	Mult_16_inst (
	.dataa ( Time_us ),
	.result ( Dist_x100 )
	);
	
/****************总状态机********************/
	 parameter 	IDLE = 2'd0,
							START = 2'd1,
							MEASR= 2'd2,
							ERR	 = 2'd3;
	
	reg rTRIG;
	reg [2:0]sta_sr04;
	reg [4:0]substp;
	reg first;
	reg [4:0]cnt;
	reg rDat_Rdy;
	reg rTime_Mark;

always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		rDist_mm <= 1'b0;
		Time_us <= 1'b0;
		first	<= 1'b1;
		En_cnt <= 1'b0;
		rTRIG <= 1'b0;
		En_delay <= 1'b0;
		delay_cnt<= 16'd12;
		sta_sr04 <= IDLE;
		substp <= 1'b0;
		rTime_Mark <=1'b0;
	end
	else begin
		En_delay <= 1'b0;			//触发性信号复位
		rDat_Rdy <= 1'b0;
		rTime_Mark <= 1'b0;
		if(En&Edge_Detect_Rdy)
			case(sta_sr04)
			IDLE:begin
				if(vclk)
					sta_sr04 <= START;
				else
					sta_sr04 <= IDLE;
			end
			START:begin												//开始测量，发送脉冲
				if(first)begin
					first <= 1'b0;
					rTRIG	<= 1'b1;
					En_delay <= 1'b1;
				end
				else if(dy_timup)begin
					first <= 1'b1;
					rTRIG	<= 1'b0;
					rTime_Mark <= 1'b1;						//测量开始，触发时间戳
					sta_sr04 <= MEASR;
				end
				else
				  sta_sr04 <= START;
			end
			MEASR:begin
				case(substp)
				5'd0://----------------------------------------------------
					if(!ECHO)										//接收端为低，信号正常，可以放下进行
						substp <= substp + 1'b1;
					else
						substp <= 5'b0;
				5'd1:
				if(L2H_Sig)begin						//接收端上升沿，开始计时
						En_cnt <= 1'b1;
						substp <= substp + 1'b1;
					end
					else
						substp <= 5'b1;
				5'd2:
					if(H2L_Sig)begin
						En_cnt <= 1'b0;
						Time_us <= Time_us_dual>>1;
						substp <= substp + 1'b1;
					end
					else if(OverFlow)begin				//计时模块溢出，约65ms未见下降沿表示测量超时
						En_cnt <= 1'b0;
						rDist_mm <= 1'b0;
						rDat_Rdy <= 1'b1;
						substp <= 1'b0;
						sta_sr04 <= IDLE;
					end
					else
						substp <= 5'd2;			
				5'd3:
					substp <= substp + 1'b1;
				5'd4:begin
					rDist_mm <= Dist_x100/24'd1000;
					rDat_Rdy <= 1'b1;
					substp <= 1'b0;
					sta_sr04 <= IDLE;
				end
				endcase
			end
			endcase
	end

assign Dist_mm = rDist_mm[15:0];
assign TRIG = rTRIG;
assign Dat_Rdy_Sig = rDat_Rdy;
assign Time_Mark = rTime_Mark;
assign STA = sta_sr04;

endmodule



/**********************END OF FILE COPYRIGHT @2016************************/	
