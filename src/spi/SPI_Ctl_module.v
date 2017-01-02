/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�������ƣ�SPI_Ctl_module
//����������SPIͨ�ſ���,�����ͽ���ģ�飬�Ͳ����ʷ���������ͣ��CSN�Զ�ģʽʱ�����
//��	 �ߣ�dammstanger
//��	 �ڣ�20160805
/*************************************************************************/	
module SPI_Ctl_module 
(
    CLK, RSTn, En, EnTx_Sig, EnRx_Sig, Tx_Busy_Sig, EnBuadcnt, CSN
);
	input CLK;
	input RSTn;
	input En;
	output EnTx_Sig;
	output EnRx_Sig;
	input Tx_Busy_Sig;
	output EnBuadcnt;
	output CSN;
	
	 /**********************************/
	 reg rEnBuadcnt;
	 reg rCSN;
	 reg [3:0]sta_BDR;

	 /**********************************/
always @ ( posedge CLK or negedge RSTn )
	if( !RSTn )begin
		sta_BDR <= 1'b0;
		rEnBuadcnt <= 1'b0;
		rCSN <= 1'b1;
	end
	else begin
		case(sta_BDR)
		4'b0:begin
		if(En)begin									//�շ�ʹ��
			rCSN <= 1'b0;
			rEnBuadcnt <= 1'b1;				//���������ʷ�����
			sta_BDR <= sta_BDR + 1'b1;
			end
		end
		4'd1:
		sta_BDR <= sta_BDR + 1'b1; 	//��ʱһ��ʱ��
		4'd2:begin
			if(!Tx_Busy_Sig)begin			//дģ���ڲ����ʷ���ʱʼ�չ�������֮�жϽ���
				rCSN <= 1'b1;
				rEnBuadcnt <= 1'b0;			//ֹͣ�����ʷ�����
				sta_BDR <= 1'b0;
			end
		end
	endcase
	end

assign CSN = rCSN;
assign EnTx_Sig = En;
assign EnRx_Sig = En;
assign EnBuadcnt = rEnBuadcnt;
endmodule

