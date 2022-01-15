using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Weather;
using Toybox.Math;
using Toybox.System as Sys;
using Toybox.Activity as Activity;

class TimeInfo {

	private var mTodayTime;
	private var mTodayDay;
	private var mSunTimes;

	function initialize() {
		// calcSunTimes();
	}
   
	function getFormattedDay() {

		if (dayChanged()) {
			var dayOfWeek = mTodayTime.day_of_week;
			var day = mTodayTime.day.format("%02d");
			mTodayDay = {
				2 => ["MON " + day, 342],
				3 => ["TUE " + day, 342],
				4 => ["WED " + day, 344],
				5 => ["THU " + day, 342],
				6 => ["FRI " + day, 345],
				7 => ["SAT " + day, 344],
				1 => ["SUN " + day, 343]
			  }[dayOfWeek];
		}
		
		return mTodayDay;
	}    

	function getWeather() {
		var conditions = Weather.getCurrentConditions();    
		var v = conditions.condition;
		var icon ="";
		var T;

		if (v==0||v==40){T = "A";} // Clear
		else if(v==53) {T="";} // Unknown
		else if(v==1||v==22||v==23||v==52) {T= "B";} // Partly clouds
		else if(v==2) {T= "C";} // Mostly clouds
		else if(v==20) {T= "D";} // Heavy clouds
		else if(v==8||v==9||v==29||v==30||v==33||v==35||v==36||v==38||v==39||v==48) {T= "m";} // Fog - Haze
		else if(v==4||v==7||v==10||v==16||v==17||v==18||v==19||v==21||v==34||v==43||v==44||v==46||v==47||v==51) {T= "l";} // Snow
		else if(v==6||v==12||v==28) {T= "n";} // Thunder
		else if(v==5||v==32||v==35||v==37||v==41||v==42) {T= "o";} // Wind
		else {T="k";} // Rain

		return T;
	}

	/**
		* With thanks to ruiokada. Adapted, then translated to Monkey C, from:
		* https://gist.github.com/ruiokada/b28076d4911820ddcbbc
		*
		* Calculates sunrise and sunset in local time given latitude, longitude, and tz.
		*
		* Equations taken from:
		* https://en.wikipedia.org/wiki/Julian_day#Converting_Julian_or_Gregorian_calendar_date_to_Julian_Day_Number
		* https://en.wikipedia.org/wiki/Sunrise_equation#Complete_calculation_on_Earth
		*
		* @method getSunTimes
		* @param {Float} lat Latitude of location (South is negative)
		* @param {Float} lng Longitude of location (West is negative)
		* @param {Integer || null} tz Timezone hour offset. e.g. Pacific/Los Angeles is -8 (Specify null for system timezone)
		* @param {Boolean} tomorrow Calculate tomorrow's sunrise and sunset, instead of today's.
		* @return {Array} Returns array of length 2 with sunrise and sunset as floats.
		*                 Returns array with [null, -1] if the sun never rises, and [-1, null] if the sun never sets.
		*/
	function getSunTimes(lat, lng, tz, tomorrow) {

		// Use double precision where possible, as floating point errors can affect result by minutes.
		lat = lat.toDouble();
		lng = lng.toDouble();

		var now = Time.now();
		if (tomorrow) {
			now = now.add(new Time.Duration(24 * 60 * 60));
		}
		var d = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var rad = Math.PI / 180.0d;
		var deg = 180.0d / Math.PI;
		
		// Calculate Julian date from Gregorian.
		var a = Math.floor((14 - d.month) / 12);
		var y = d.year + 4800 - a;
		var m = d.month + (12 * a) - 3;
		var jDate = d.day
			+ Math.floor(((153 * m) + 2) / 5)
			+ (365 * y)
			+ Math.floor(y / 4)
			- Math.floor(y / 100)
			+ Math.floor(y / 400)
			- 32045;

		// Number of days since Jan 1st, 2000 12:00.
		var n = jDate - 2451545.0d + 0.0008d;
		//Sys.println("n " + n);

		// Mean solar noon.
		var jStar = n - (lng / 360.0d);
		//Sys.println("jStar " + jStar);

		// Solar mean anomaly.
		var M = 357.5291d + (0.98560028d * jStar);
		var MFloor = Math.floor(M);
		var MFrac = M - MFloor;
		M = MFloor.toLong() % 360;
		M += MFrac;
		//Sys.println("M " + M);

		// Equation of the centre.
		var C = 1.9148d * Math.sin(M * rad)
			+ 0.02d * Math.sin(2 * M * rad)
			+ 0.0003d * Math.sin(3 * M * rad);
		//Sys.println("C " + C);

		// Ecliptic longitude.
		var lambda = (M + C + 180 + 102.9372d);
		var lambdaFloor = Math.floor(lambda);
		var lambdaFrac = lambda - lambdaFloor;
		lambda = lambdaFloor.toLong() % 360;
		lambda += lambdaFrac;
		//Sys.println("lambda " + lambda);

		// Solar transit.
		var jTransit = 2451545.5d + jStar
			+ 0.0053d * Math.sin(M * rad)
			- 0.0069d * Math.sin(2 * lambda * rad);
		//Sys.println("jTransit " + jTransit);

		// Declination of the sun.
		var delta = Math.asin(Math.sin(lambda * rad) * Math.sin(23.44d * rad));
		//Sys.println("delta " + delta);

		// Hour angle.
		var cosOmega = (Math.sin(-0.83d * rad) - Math.sin(lat * rad) * Math.sin(delta))
			/ (Math.cos(lat * rad) * Math.cos(delta));
		//Sys.println("cosOmega " + cosOmega);

		// Sun never rises.
		if (cosOmega > 1) {
			return [null, -1];
		}
		
		// Sun never sets.
		if (cosOmega < -1) {
			return [-1, null];
		}
		
		// Calculate times from omega.
		var omega = Math.acos(cosOmega) * deg;
		var jSet = jTransit + (omega / 360.0);
		var jRise = jTransit - (omega / 360.0);
		var deltaJSet = jSet - jDate;
		var deltaJRise = jRise - jDate;

		var tzOffset = (tz == null) ? (Sys.getClockTime().timeZoneOffset / 3600) : tz;
		return [
			/* localRise */ (deltaJRise * 24) + tzOffset,
			/* localSet */ (deltaJSet * 24) + tzOffset
		];
	}

	function dayChanged() {
		var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		if (mTodayTime == null || now.day != mTodayTime.day) {
			mTodayTime = now;
			return true;
		}
		return false;
	}

	function getSunAngle(time, minAngle, maxAngle) {
		if (mSunTimes == null || dayChanged()) {
			calcSunTimes();
		}

		var now = time.hour + time.min/60.0;
		if (mSunTimes != null && mSunTimes[0] < now && now < mSunTimes[1]) {
			return (mSunTimes[1] - now)*(maxAngle - minAngle)/(mSunTimes[1] - mSunTimes[0]);
		}

		return 0;
	}
	
	function calcSunTimes() {
		var location = Activity.getActivityInfo().currentLocation;
		// if (location != null) {
			// mSunTimes = getSunTimes(mLocation.lat, mLocation.lon, null, /* tomorrow */ false);		
			mSunTimes = getSunTimes(52.0439927, 4.3909217, null, /* tomorrow */ false);
		// }	
	}
}