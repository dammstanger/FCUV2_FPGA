
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//文件名称：delayNms_module
//功	 能：定时Ns，时间到输出一个脉冲,不循环
//作	 者：dammstanger
//日	 期：201608013
/*************************************************************************/	
module delayNms_module 
(
    CLK, RSTn, En, Nms, timeup
);

   input CLK;
	 input RSTn;
	 input En;
	 input [15:0]Nms;
	 output timeup;
	 
	 /****************************************/
	 parameter T1MSval = 16'd49_999;					//晶振为50MHz，50M*0.001-1=49
	 
	 /***************************************/
		reg [15:0]Count;
	  reg sta;
	 always @ ( posedge CLK or negedge RSTn )
	     if( !RSTn )
		      Count <= 16'd0;
		  else if( Count == T1MSval||sta==0)
		      Count <= 16'd0;
		  else 
		      Count <= Count + 1'b1;
	
    /****************************************/	
				
    reg [15:0]Countms;

	 always @ ( posedge CLK or negedge RSTn )
      if( !RSTn )begin
				sta <= 1'b0;
		    Countms <= 1'd0;
			end
		  else
				case(sta)
				1'b0:
					if(En)
						sta <= 1'b1;
				1'b1:
					if( Count == T1MSval )
						Countms <= Countms + 1'b1;
					else if( Countms==Nms)begin
						Countms <= 16'd0;
						sta <= 1'b0;
					end
				endcase
	
   /********************************************/
	 
	 assign timeup = (Countms==Nms)? 1'b1 : 1'b0;
	 
	 /********************************************/
		      

endmodule