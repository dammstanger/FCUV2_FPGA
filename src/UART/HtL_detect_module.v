/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//ģ�����ƣ�HtL_detect_module
//�����������½��صļ��ģ��
//��	 �ߣ�dammstanger
//��	 �ڣ�20160426
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
