proc import out=weather
	datafile="/home/u47247130/sasuser.v94/STAT802/weather.csv"
	replace;
run;

/*standardise*/
proc standard data = weather out = weather_std mean = 0 std =1;
var temperature--wind_speed_knots;
run;

proc corr data=weather_std;
run;

/*pca-no observable patterns */
proc princomp data = weather_std plots(ncomp = 2)=all out=pca;
var temperature--wind_speed_knots;
id forecast;
run;

/*cluster with different variables*/
proc fastclus data=pca summary maxc=7 maxiter=1000 converge=0
					mean=mean out=cluster1 cluster=preclus;
	var Prin1: Prin2: Prin3: Prin4:;
run;
proc sgplot data=pca;
	scatter y=Prin2 x=Prin1 / datalabel=forecast;
run;

proc sgplot data=pca;
	scatter y=Prin2 x=Prin1 / group=forecast ;
run;

proc fastclus data=weather_std summary maxc=7 maxiter=99 converge=0
					mean=mean out=cluster2 cluster=preclus;
	var temperature: relative_humidity: wind_direction_deg: wind_speed_knots:;
run;

proc fastclus data=weather_std summary maxc=3 maxiter=99 converge=0
					mean=mean out=cluster3 cluster=preclus;
	var temperature: relative_humidity: wind_direction_deg: wind_speed_knots:;
run;

/*visualise different clusters*/
/*cluster1*/
proc candisc data=cluster1 out=canonical1 noprint;
class preclus;
	var Prin1--Prin4;
run;
proc sgplot data=canonical1;
	scatter y=can2 x=can1 / group=preclus datalabel=forecast;
run;

/*cluster2*/
proc candisc data=cluster2 out=canonical2 noprint;
class preclus;
	var temperature--wind_speed_knots;
run;
proc sgplot data=canonical2;
	scatter y=can2 x=can1 / group=preclus datalabel=forecast;
run;
proc sgplot data=canonical2;
	scatter y=can2 x=can1 / group=forecast;
	where forecast = 'rain' or forecast = 'light';
run;

/*cluster3*/
proc candisc data=cluster3 out=canonical3 noprint;
class preclus;
	var temperature--wind_speed_knots;
run;

proc sgplot data=canonical3;
	scatter y=can2 x=can1 / group=preclus datalabel=forecast;
run;

/*time dimension*/
data weather_hourly;
set cluster1;
hour = timepart(date)/3600;
day = datepart(date);
format hour 4.1;
format day day6.;
run;
proc sgplot data = weather_hourly;
	scatter y=day x= hour / group=preclus;
	run;

/*detect cluster 6*/
proc freq data= cluster2;
table forecast*preclus;
run;

data weather;
set weather;
rename temperature=temp;
rename relative_humidity=humidity;
rename wind_direction_deg=windirection;
rename wind_speed_knots=windspeed;
run;

data comparison;
set weather;
set cluster2;
run;

/*compare with the real number*/
proc gplot data=comparison;
 	plot temp*preclus = forecast;
run;
proc gplot data=comparison;
 	plot humidity*preclus = forecast;
run;
proc gplot data=comparison;
 	plot windirection*preclus = forecast;
run;
proc gplot data=comparison;
 	plot windspeed*preclus = forecast;
run;

proc means data=comparison;
where preclus=6;
var temp humidity windirection windspeed;
run;


