
/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�ļ����ƣ�delayNus_module
//��	 �ܣ���ʱNms��ʱ�䵽���һ������,��ѭ��
//��	 �ߣ�dammstanger
//��	 �ڣ�201608011
/*************************************************************************/	
module delayNus_module 
(
    CLK, RSTn, En, Nus, timeup
);

   input CLK;
	 input RSTn;
	 input En;
	 input [15:0]Nus;
	 output timeup;
	 
	 /****************************************/
	 parameter T1USval = 16'd49;					//����Ϊ50MHz��50M*0.000001-1=49
	 
	 /***************************************/
		reg [15:0]Count;
	  reg sta;
	 always @ ( posedge CLK or negedge RSTn )
	     if( !RSTn )
		      Count <= 16'd0;
		  else if( Count == T1USval||sta==0)
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
					if( Count == T1USval )
						Countms <= Countms + 1'b1;
					else if( Countms==Nus)begin
						Countms <= 16'd0;
						sta <= 1'b0;
					end
				endcase
	
   /********************************************/
	 
	 assign timeup = (Countms==Nus)? 1'b1 : 1'b0;
	 
	 /********************************************/
		      

endmodule