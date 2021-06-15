ROW_BUFF	ROW_BUFF_inst (
	.clock ( clock_sig ),
	.data ( data_sig ),
	.rdreq ( rdreq_sig ),
	.sclr ( sclr_sig ),
	.wrreq ( wrreq_sig ),
	.almost_full ( almost_full_sig ),
	.empty ( empty_sig ),
	.full ( full_sig ),
	.q ( q_sig ),
	.usedw ( usedw_sig )
	);
