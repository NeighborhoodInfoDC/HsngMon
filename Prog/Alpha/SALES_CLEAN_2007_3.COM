$ set verify
$ set noon
$!
$! Set RMS (I/O) parameters for better performance.
$!
$ set rms /block_count=64
$ set rms /buffer_count=64 /disk
$ set rms /buffer_count=64 /indexed
$ set rms /buffer_count=64 /relative
$ set rms /buffer_count=64 /sequential
$ set rms /extend_quantity=65535
$!
$! SALES_CLEAN_2007_3
$!
$ set default DISK$S_USER02:[DCDATA.HSNGMON.PROG]
$ sas DISK$S_USER02:[DCDATA.HSNGMON.PROG]SALES_CLEAN_2007_3.SAS;2 /fullstimer /noterminal 
$ job_status = f$integer ($status)
$!
$! Check the current disk quota situation.
$!
$ quota
$!
$! If SAS didn't delete the WORK directory, do it now.
$!
$ if f$search("sas$worklib:*.*") .nes. "" then -
	@ui$pub:deldir sas$worklib:
$!
$! All done. Exit with status code of SAS run.
$!
$ exit 'job_status'
