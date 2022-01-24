using Toybox.Math;
using Toybox.System as Sys;
using Toybox.Activity as Activity;

class ActivityInfo {

private var mTodayTime;
	private var mTodayDay;
	private var mSunTimes;

	function initialize() {
	}
   
	function getMoveBarLevel() {
        return ActivityMonitor.getInfo().moveBarLevel;
	}    

}