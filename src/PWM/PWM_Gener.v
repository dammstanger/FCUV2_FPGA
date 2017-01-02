/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：PWM_Gener
//工程描述：矩阵波生成器
//作	 者：dammstanger
//日	 期：20160916
/*************************************************************************/	
module PWM_Gener (
input CLK,
input RSTn,
input En,
input [15:0]Channel1,
input [15:0]Channel2,
input [15:0]Channel3,
input [15:0]Channel4,
input [15:0]Channel5,
input [15:0]Channel6,
input [15:0]Channel7,
input [15:0]Channel8,
output Sig_Out1,
output Sig_Out2,
output Sig_Out3,
output Sig_Out4,
output Sig_Out5,
output Sig_Out6,
output Sig_Out7,
output Sig_Out8
);

parameter _1ustime = 6'd49;				//周期1us 50MHz 
parameter Ttime = 32'd2499;		//周期2.5ms PLL倍频，50MHz 

reg [7:0]rSig_Out;
reg [6:0]timecnt_1us;
reg [31:0]timecnt;

always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		timecnt_1us = 1'b0;
	end
	else if(timecnt_1us==_1ustime||!En)
		timecnt_1us = 1'b0;
	else
		timecnt_1us = timecnt_1us + 1'b1;

always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		timecnt = 1'b0;
	end
	else if(timecnt==Ttime||!En)
		timecnt = 1'b0;
	else if(timecnt_1us==_1ustime)
		timecnt = timecnt + 1'b1;

//============CH1======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[0] = 1'b0;
	end
	else if(Channel1==0)
		rSig_Out[0] = 1'b0;	
	else if(timecnt>=Channel1-1)
		rSig_Out[0] = 1'b0;	
	else
		rSig_Out[0] = 1'b1;	

assign Sig_Out1 = En? rSig_Out[0] : 1'b0;

//============CH2======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[1] = 1'b0;
	end
	else if(Channel2==0)
		rSig_Out[1] = 1'b0;	
	else if(timecnt>=Channel2-1)
		rSig_Out[1] = 1'b0;	
	else
		rSig_Out[1] = 1'b1;	

assign Sig_Out2 = En? rSig_Out[1] : 1'b0;

//============CH3======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[2] = 1'b0;
	end
	else if(Channel3==0)
		rSig_Out[2] = 1'b0;	
	else if(timecnt>=Channel3-1)
		rSig_Out[2] = 1'b0;	
	else
		rSig_Out[2] = 1'b1;	

assign Sig_Out3 = En? rSig_Out[2] : 1'b0;

//============CH4======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[3] = 1'b0;
	end
	else if(Channel4==0)
		rSig_Out[3] = 1'b0;	
	else if(timecnt>=Channel4-1)
		rSig_Out[3] = 1'b0;	
	else
		rSig_Out[3] = 1'b1;	

assign Sig_Out4 = En? rSig_Out[3] : 1'b0;

//============CH5======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[4] = 1'b0;
	end
	else if(Channel5==0)
		rSig_Out[4] = 1'b0;	
	else if(timecnt>=Channel5-1)
		rSig_Out[4] = 1'b0;	
	else
		rSig_Out[4] = 1'b1;	

assign Sig_Out5 = En? rSig_Out[4] : 1'b0;

//============CH6======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[5] = 1'b0;
	end
	else if(Channel6==0)
		rSig_Out[5] = 1'b0;	
	else if(timecnt>=Channel6-1)
		rSig_Out[5] = 1'b0;	
	else
		rSig_Out[5] = 1'b1;	

assign Sig_Out6 = En? rSig_Out[5] : 1'b0;

//============CH7======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[6] = 1'b0;
	end
	else if(Channel7==0)
		rSig_Out[6] = 1'b0;	
	else if(timecnt>=Channel7-1)
		rSig_Out[6] = 1'b0;	
	else
		rSig_Out[6] = 1'b1;	

assign Sig_Out7 = En? rSig_Out[6] : 1'b0;

//============CH8======================		
always@(posedge CLK, negedge RSTn)
	if(!RSTn)begin
		rSig_Out[7] = 1'b0;
	end
	else if(Channel8==0)
		rSig_Out[7] = 1'b0;	
	else if(timecnt>=Channel8-1)
		rSig_Out[7] = 1'b0;	
	else
		rSig_Out[7] = 1'b1;	

assign Sig_Out8 = En? rSig_Out[7] : 1'b0;


endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
