/**********************DAMMSTANGER COPYRIGHT @2016************************/	
//�������ƣ�SPI_module
//����������SPIģ��
//��	 �ߣ�dammstanger
//��	 �ڣ�20160809
/*************************************************************************/	
module SPI_module (
input CLK,
input RSTn,
input En,
input  PIN_MISO,
output PIN_CLK,
output PIN_MOSI,
output PIN_CSN,

input [7:0]SBUF,
output [7:0]RBUF,
output Dat_Rdy_Sig,
output Busy_Flg,
output SPI_Rdy
);

parameter MODE = 1'b1,										//ģʽ����1����0
					CLK_FREE_LEVEL= 1'b0,					//ʱ�ӿ��е�ƽ����1����0
					BAUDRARE_SCALER = 8'd5;				//��Ƶϵ��1-32��Ĭ������50MHZ����£�=1����Ƶ.=5 1.56MHz

wire Rx_Rdy_Sig;
wire Tx_Busy_Sig;

wire EnRx_Sig;
wire EnTx_Sig;


wire H2L_Sig;
wire L2H_Sig;
wire Baudclk;
wire EnBuadcnt;
wire Edge_Detect_Rdy;

SPI_Baudrate_Module #(BAUDRARE_SCALER,CLK_FREE_LEVEL)SPI_Baudrate_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(EnBuadcnt),
	.Baudclk(Baudclk)
);

Sig_Edge_Detect Sig_Edge_Detect_U1(	//�����źŲ������ⲿ�����MISO���ǲ����Ĳ�����ʱ��Baudclk
	.CLK( CLK ),
	.RSTn( RSTn ),
	.Init_Rdy(Edge_Detect_Rdy),
	.Pin_In(Baudclk), 									
	.H2L_Sig(H2L_Sig), 
	.L2H_Sig(L2H_Sig)
);

SPI_Ctl_module #(CLK_FREE_LEVEL)SPI_Ctl_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.En(En&Edge_Detect_Rdy),
	.EnRx_Sig(EnRx_Sig),
	.EnTx_Sig(EnTx_Sig),
	.EnBuadcnt(EnBuadcnt),
	.Tx_Busy_Sig(Tx_Busy_Sig),
	.Rx_Dat_Rdy(Rx_Rdy_Sig),
	.CSN( PIN_CSN )
);


SPI_Rx_module SPI_Rx_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.MISO(PIN_MISO),
	.L2H_Sig(L2H_Sig),
	.En(EnRx_Sig),
	.Rdy_Sig(Rx_Rdy_Sig),
	.Data(RBUF)
);

SPI_Tx_module #(CLK_FREE_LEVEL)SPI_Tx_module_U1(
	.CLK( CLK ),
	.RSTn( RSTn ),
	.MOSI(PIN_MOSI),
	.H2L_Sig(H2L_Sig),
	.L2H_Sig(L2H_Sig),
	.En(EnTx_Sig),
	.Busy_Sig(Tx_Busy_Sig),
	.Data(SBUF)
);

assign Busy_Flg = Tx_Busy_Sig;			//���͹���Ҫ���ڽ��չ��̣�ȡʱ�䳤���ж��Ƿ����
assign Dat_Rdy_Sig = Rx_Rdy_Sig;		//���յ����ݱ�־
assign PIN_CLK = Baudclk;
assign SPI_Rdy = Edge_Detect_Rdy;
endmodule




/**********************END OF FILE COPYRIGHT @2016************************/	
