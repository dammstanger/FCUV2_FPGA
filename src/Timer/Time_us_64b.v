
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//文件名称：Time_us_64b
//功	 能：us计时模块，64位最大计数2^64-1us 输入时钟50MHz
//作	 者：dammstanger
//日	 期：20161003
/*************************************************************************/	
module Time_us_64b 
(
    CLK, RSTn, En, Nus, OVERFLW
);
   input CLK;
	 input RSTn;
	 input En;
	 output [63:0]Nus;
	 output OVERFLW;
	 
	 /****************************************/
	 parameter T1USval = 6'd49;					//晶振为50MHz，50M*0.000001-1=49
	 
	 /***************************************/
		reg [5:0]Count;
	always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
			Count <= 6'd0;
		else if( (Count == T1USval)||(!En))
			Count <= 6'd0;
		else 
			Count <= Count + 1'b1;
	
    /****************************************/	
		reg rOVERFLW;
    reg [63:0]Countus;
	 always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )begin
			Countus <= 1'd0;
			rOVERFLW <= 1'b0;
		end
		else begin
			if(En)begin
				if(Count == T1USval)
					Countus <= Countus + 1'b1;
				else
					Countus <= Countus;
			end
			else 
				Countus <= 1'b0;
				
			if(Countus==16'hffff)
				rOVERFLW <= 1'b1;
			else
				rOVERFLW <= 1'b0;
		end
	
   /********************************************/
	 assign Nus = Countus;
	 assign OVERFLW = rOVERFLW;

	 /********************************************/
		      

endmodule