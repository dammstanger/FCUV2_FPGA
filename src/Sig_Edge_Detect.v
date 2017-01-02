/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：Sig_Edge_Detect
//工程描述：信号边缘检测
//作	 者：dammstanger
//日	 期：20160726
/*************************************************************************/	
module Sig_Edge_Detect 
(
    CLK, RSTn, Init_Rdy, Pin_In, H2L_Sig, L2H_Sig
);

   input CLK;
	 input RSTn;
	 output Init_Rdy;
	 input Pin_In;
	 output H2L_Sig;
	 output L2H_Sig;
	 
	 /**********************************/
	 
	 parameter T100US = 20'd499_999;			//晶振为50MHz，50M*0.01-1=4_99999
	 
	 /**********************************/
	 
	 reg [19:0]Count1;
	 reg isEn;
	 always @ ( posedge CLK or negedge RSTn )
	     if( !RSTn )
		      begin
		          Count1 <= 11'd0;
		          isEn <= 1'b0;
				end	
	     else if( Count1 == T100US )		//在初始化的时候电平可能会持续1~10us的不稳定状态（笔者估计），延迟100us的目的是为了过滤这个不稳定状态。
				isEn <= 1'b1;								
		  else
		      Count1 <= Count1 + 1'b1;
				
    /********************************************/
	 
	 reg H2L_F1;
	 reg H2L_F2;
	 reg L2H_F1;
	 reg L2H_F2;
	 
	 always @ ( posedge CLK or negedge RSTn )
	     if( !RSTn )
		      begin
				   H2L_F1 <= 1'b1;
					 H2L_F2 <= 1'b1;
					 L2H_F1 <= 1'b0;
					 L2H_F2 <= 1'b0;
			   end
		  else
		      begin
					 H2L_F1 <= Pin_In; 
					 H2L_F2 <= H2L_F1;
					 L2H_F1 <= Pin_In;
					 L2H_F2 <= L2H_F1;
				end
				
    /***********************************/
	 

	 assign H2L_Sig = isEn ? ( H2L_F2 & !H2L_F1 ) : 1'b0;
	 assign L2H_Sig = isEn ? ( !L2H_F2 & L2H_F1 ) : 1'b0;
	assign Init_Rdy = isEn;
	 
	 
	 /***********************************/
	 
endmodule

