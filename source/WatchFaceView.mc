import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;

class WatchFaceView extends WatchUi.WatchFace {

	var displayHeight = null;
	var displayWidth = null;
    var font;
    var bezelText;
    var dateText;
    var mHoursFont;
    var mMinutesFont;
    var mDataFont;
    var mWindIcons;
    var mTimeInfo;
    var mSunriseIcon;
    var mSunsetIcon;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) as Void {
        font = new Font();
        bezelText = new BezelText();
        mTimeInfo = new TimeInfo();

        mHoursFont = WatchUi.loadResource(Rez.Fonts.HoursFont);
        mMinutesFont = WatchUi.loadResource(Rez.Fonts.SecondsFont);
        mDataFont = WatchUi.loadResource(Rez.Fonts.DateFont);

        mSunriseIcon = WatchUi.loadResource(Rez.Fonts.IconSunrise);
        mSunsetIcon = WatchUi.loadResource(Rez.Fonts.IconSunset);
        mWindIcons = WatchUi.loadResource(Rez.Fonts.IconsWind);

        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc) as Void {

        View.onUpdate(dc);

        displayHeight = dc.getHeight();
        displayWidth = dc.getWidth();

        // Get and show the current time
        var clockTime = System.getClockTime();
		var hours =  clockTime.hour.format("%02d");
        var minutes =  clockTime.min.format("%02d");
        
		var halfDCWidth = dc.getWidth() / 2;
		var halfDCHeight = dc.getHeight() / 2;

        var totalWidth = dc.getTextWidthInPixels(hours, mHoursFont);
		var x = halfDCWidth - (totalWidth / 2);

		// Draw hours.
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			halfDCWidth,
			halfDCHeight - 5,
			mHoursFont,
			hours,
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);

        // Minutes
        dc.setColor(0xaaaaaa, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			halfDCWidth,
			halfDCHeight + 50,
			mMinutesFont,
			minutes,
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);

        // Notifications
        var settings = System.getDeviceSettings();
        var notifications = settings.notificationCount.format("%02d");
        var textWidth = dc.getTextWidthInPixels(notifications, mDataFont) + 4;
        dc.setColor(0x888888, 0x888888);
        dc.fillRectangle(halfDCWidth - textWidth/2, halfDCHeight - 65, textWidth, 26);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
		dc.drawText(
			halfDCWidth,
			halfDCHeight - 54,
			mDataFont,
			notifications,
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);
        
        // Draw day of week
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var day = mTimeInfo.getFormattedDay();
        if (day != null) {
            bezelText.draw(dc, day[0], day[1], font);
        }

        // Minutes arch
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
    	dc.drawCircle(dc.getWidth() / 2, dc.getHeight() / 2, displayWidth / 3);
        if (clockTime.min > 0 && clockTime.min < 60) {
            System.println("min: " + clockTime.min);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, displayWidth / 3, Graphics.ARC_CLOCKWISE, 90, 90 + (60 - clockTime.min) * 6);
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
            dc.fillCircle(dc.getWidth()/2 + Math.sin(Math.toRadians(clockTime.min*6)) * (displayWidth/3), dc.getHeight()/2 - Math.cos(Math.toRadians(clockTime.min*6)) * (displayWidth/3), 4);
        }
        
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 3, 57);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 123, 177);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 183, 237);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 243, 297);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 303, 357);

        drawWeatherData(dc);
        drawSunData(dc, Gregorian.info(Time.now(), Time.FORMAT_SHORT));
    }

    function drawSunData(dc, clockTime) {
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 65, 115);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(70, 9, mSunriseIcon, "A", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(192, 9, mSunsetIcon, "B", Graphics.TEXT_JUSTIFY_CENTER);

        var sunAngle = mTimeInfo.getSunAngle(clockTime, 65, 115);
        if (sunAngle > 0) {
            dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 65, 65 + sunAngle);
        }
    }

    function drawWeatherData(dc) {
        var w = mTimeInfo.getWeather();

        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_COUNTER_CLOCKWISE, 123, 177);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(dc.getWidth() / 2, dc.getWidth() / 2, (displayWidth / 2) - 2, Graphics.ARC_CLOCKWISE, 177, 177 - (w[2]*54/100.0));
        dc.drawText(28, 85, mWindIcons, "W", Graphics.TEXT_JUSTIFY_CENTER);
        bezelText.draw(dc, w[4], 300, font);
        bezelText.draw(dc, w[1] + "°", 60, font);

    }


    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
