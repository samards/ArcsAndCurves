using Toybox.Math;
using Toybox.System as Sys;
using Toybox.ActivityMonitor as ActMon;
using Toybox.Activity;

class ActivityInfo {

	function initialize() {
	}
   
	function getActivityInfo() {
		var info = Activity.getActivityInfo();
		var heartRate = info.currentHeartRate;
		
		if (heartRate == null && ActMon has :getHeartRateHistory) {
			var HRH = ActMon.getHeartRateHistory(1, true);
			var HRS = HRH.next();
			if (HRS != null && HRS.heartRate != ActMon.INVALID_HR_SAMPLE) {
				heartRate = HRS.heartRate;
			}
		}

		heartRate = (heartRate == null ? "--" : heartRate.toString());
	
        return [ActMon.getInfo().moveBarLevel, heartRate, info.calories];
	}    

	function getDeviceStatus() {
		var settings = Sys.getDeviceSettings();
		return [settings.phoneConnected, settings.alarmCount];
	}

}