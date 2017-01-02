/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//模块名称：HtL_detect_module
//工程描述：下降沿的检测模块
//作	 者：dammstanger
//日	 期：20160426
/*************************************************************************/	
module HtL_detect_module (CLK, RSTn, Pin_In, H2L_Sig);
	input CLK;
	input RSTn;
	input Pin_In;
	output H2L_Sig;
	/********************************************/
	 
reg H2L_F1;
reg H2L_F2;
 
always @ ( posedge CLK or negedge RSTn )
		if( !RSTn )
		begin
			H2L_F1 <= 1'b1;
			H2L_F2 <= 1'b1;
		end
	else
		begin
			 H2L_F1 <= Pin_In; 
			 H2L_F2 <= H2L_F1;
		end
		
/***********************************/
 assign H2L_Sig = H2L_F2 & !H2L_F1;

endmodule

/**********************END OF FILE COPYRIGHT @2016************************/	
