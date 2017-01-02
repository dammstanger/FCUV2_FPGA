/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//工程名称：InerSig_Edge_Detect
//工程描述：信号边缘检测
//作	 者：dammstanger
//日	 期：20160816
/*************************************************************************/	
module InerSig_Edge_Detect 
(
    CLK, RSTn, Sig_In, H2L_Sig, L2H_Sig
);

   input CLK;
	 input RSTn;
	 input Sig_In;
	 output H2L_Sig;
	 output L2H_Sig;
	 
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
					 H2L_F1 <= Sig_In; 
					 H2L_F2 <= H2L_F1;
					 L2H_F1 <= Sig_In;
					 L2H_F2 <= L2H_F1;
				end
				
    /***********************************/

	 assign H2L_Sig = H2L_F2 & !H2L_F1 ;
	 assign L2H_Sig = !L2H_F2 & L2H_F1 ;
	  
	 /***********************************/
	 
endmodule

