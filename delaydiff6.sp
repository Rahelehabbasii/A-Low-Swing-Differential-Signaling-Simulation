** ---------------- U Model ----------------------** 
.include model.sp
.TEMP 25.0000
********************************************************
.TRAN 1p Deadline UIC
*--------------------------------1M=1E+6
.PARAM supply=0.9
.PARAM gnd=0                                                   *
*.PARAM Deadline = '(3/2)*tp'
.PARAM Deadline = 65n
.PARAM tp = 15n
*.PARAM twr = 2E-9
.param twr=30
.PARAM tn=50n						                           *	
.PARAM tr = 0.001n
.PARAM tf = 0.001n
.PARAM td = 'tp/2'
.PARAM td1='td+1n'                                               *
.PARAM L_wire=6m					                           *
.PARAM Ln=32n                                                 *
.PARAM Wn=1.0u                                                   *
****************************************************************
VVDD VDD 0 supply
.GLOBAL VDD

.OPTION Post NoMod Accurate Probe Probe Method=Gear 

****************** input_Source	---- main circuit ***********
Vin1 in1 gnd pulse (0 supply td tr tf 'tp/2' tp) 
Vin2 in2 gnd  pulse (supply 0 td tr tf 'tp/2' tp)

*VLoad nLoad 0 DC=0 PULSE(0 supply td1 tr tf twr tn)
VLoad nLoad 0 DC=supply

******************     Main Circuit 	*************************
*U1 inL1 inL2 inL3 inL4 gnd outL1 outL2 outL3 outL4 gnd Stripline  lumps=2000 L=L_wire	*

RL1 inL1 outL1 0
RL2 inL2 outL2 0
RL3 inL3 outL3 0
RL4 inL4 outL4 0

XDriver1 in1 inL1 inL2 nLoad Driver
XReceiver1 outL1 outL2 OUT1 Receiver
cl1	OUT1 gnd 20fF			     					        		*

XDriver2 in2 inL3 inL4 nLoad Driver
XReceiver2 outL3 outL4 OUT2 Receiver
cl3	OUT2 gnd 20fF			     					        		*

.print v(in1) v(out1) v(inL1) v(outL1) v(nLoad) v(out)
***************************-------Driver-----*******************
.SUBCKT Driver in out1 out2 nLoad

Mp1 out1 gnd VDD VDD pmos L=Ln W='2*Wn'
Mp2 out2 gnd VDD VDD pmos L=Ln W='2*Wn'

Mn1 out1 inn com gnd nmos L=Ln W=Wn
Mn2 out2 in com gnd nmos L=Ln W=Wn

*Read transistor
MLoadN com nLoad gnd gnd nmos L=Ln W=Wn

XNOT in inn INV

.ENDS Driver
****************************---- Receiver-----*****************
***************************************************
.SUBCKT Receiver in1 in2 out

Mp1 out1 GMp2 VDD VDD pmos L=Ln W='2*Wn'
Mp2 GMp2 GMp2 VDD VDD pmos L=Ln W='2*Wn'

Mn1 out1 in1 gnd gnd nmos L=Ln W=Wn
Mn2 GMp2 in2 gnd gnd nmos L=Ln W=Wn

XNOT1 out1  out11  INV
XNOT2 out11 out111 INV
XNOT3 out111 out   INV

*.print v(GMp2) v(out1)

.ENDS Receiver

********************************************
**-------------------NOT
.SUBCKT INV in out
Mp1 OUT IN VDD VDD pmos L=Ln W='2*Wn'
Mn1 OUT IN 0 0 nmos L=Ln W=Wn
.ENDS INV

.SUBCKT INV1 in out
Mp1 OUT IN VDD VDD pmos L=Ln W='4*Wn'
Mn1 OUT IN 0 0 nmos L=Ln W='2*Wn'
.ENDS INV
*---------------------------------------
********************************************
**----------asks SPICE to calculate the equivalent noise
** at both output V(outL3) and Vin1 at every 5th frequency point in the AC analysis.
* ONOISE=total output noise in V(outL3)-----INOISE=total Input noise
*.NOISE	V(outL3) Vin1 5: .NOISE output-variable, noise-input reference, interval
*V(outL3) : node output at which the noise output is summed
*Vin1 : noise input reference node
*5 : interval at which noise analysis summary is to be printed
*plot: the total voltage spectral density V(outL3) referred to the input source Vin1 =Noise spectral density.

*.AC DEC 10 100 1000MEG
*.NOISE	V(outL3) Vin1 5
*.PRINT NOISE INOISE ONOISE

*---------------------------------------
.measure TRAN MAX_LINE1 MAX V(inL1) from 20n to Deadline
.measure TRAN MIN_LINE1 MIN V(inL1) from 20n to Deadline

.measure TRAN MAX_OUTL1 MAX V(outL1) from 20n to Deadline
.measure TRAN MIN_OUTL1 MAX V(outL1) from 20n to Deadline

.measure Avg_inL1 param ='(MAX_LINE1+MIN_LINE1)/2'
.measure Avg_outL1 param ='(MAX_OUTL1+MIN_LINE1)/2'

.measure TpLH TRIG v(inL1) val=Avg_inL1 TD=20n rise=1 TARG v(outL1) val=Avg_outL1 rise=1
.measure TpHL TRIG v(inL1) val=Avg_inL1 TD=20n fall=1 TARG v(outL1) val=Avg_outL1 fall=1

.measure Tpd param ='(TpHL+TpLH)/2'

********************************avarage power************************
.measure TRAN avgpwr AVG POWER from 10ps to Deadline

***************************Energy PJ*********************************
.measure TRAN QE INTEGRAL i(VVDD) from 10ps to Deadline
.measure Energy param ='-supply*QE'
.END
