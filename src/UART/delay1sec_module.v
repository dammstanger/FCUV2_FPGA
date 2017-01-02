
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//文件名称：delay1sec_module
//功	 能：定时1s输出一个脉冲
//作	 者：dammstanger
//日	 期：20160424
/*************************************************************************/	
module delay1sec_module 
(
    CLK, RSTn, vclk
);

   input CLK;
	 input RSTn;
	 output vclk;
	 
	 /****************************************/
	 
	 parameter T1MSval = 16'd49;//DB4CE15开发板使用的晶振为50MHz，50M*0.000001-1=49_
	 
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
		      Countms <= 16'd0;
		  else if( Count == T1MSval )
		      Countms <= Countms + 16'b1;
		  else if( Countms==16'd1)
		      Countms <= 16'd0;
	
    /********************************************/
//
//	reg rPin_Out;
//	
//	always @ ( posedge CLK or negedge RSTn )
//	   if( !RSTn )
//		    begin
//					rPin_Out <= 1'b0;
//			  end
//		 else if((Countms==16'd1000)&&(rPin_Out==1'b1))
//				rPin_Out <= 1'b0;
//		 else 
//				rPin_Out <= 1'b1;
//		 
   /********************************************/
	 
	 assign vclk = (Countms==16'd1)? 1'b1 : 1'b0;
	 
	 /********************************************/
		      

endmodule