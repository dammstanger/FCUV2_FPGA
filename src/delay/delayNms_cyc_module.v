
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//文件名称：delayNms_cyc_module
//功	 能：循环定时Nms输出一个脉冲
//作	 者：dammstanger
//日	 期：201608010
/*************************************************************************/	
module delayNms_cyc_module 
(
    CLK, RSTn, vclk
);

   input CLK;
	 input RSTn;
	 output vclk;
	 
	 /****************************************/
	 parameter N_MS = 16'd100;						//要定时的毫秒数
	 parameter T1MSval = 16'd49999;		//DB4CE15开发板使用的晶振为50MHz，50M*0.001-1=49_999
	 
	 /***************************************/
	 reg [15:0]Count;

	 always @ ( posedge CLK or negedge RSTn )
	     if( !RSTn )
		      Count <= 16'd0;
		  else if( Count == T1MSval )
		      Count <= 16'd0;
		  else
		      Count <= Count + 1'b1;
	
    /****************************************/	
				
    reg [15:0]Countms;
	    
	 always @ ( posedge CLK or negedge RSTn )
        if( !RSTn )
		      Countms <= 1'd0;
		  else if( Count == T1MSval )
		      Countms <= Countms + 1'b1;
		  else if( Countms==N_MS)
		      Countms <= 16'd0;
	
   /********************************************/
	 
	 assign vclk = (Countms==N_MS)? 1'b1 : 1'b0;
	 
	 /********************************************/
		      

endmodule