using Toybox.Activity as Activity;
using Toybox.Application as App;
using Toybox.Application.Storage as Storage;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;
using Toybox.Timer as Timer;
using Toybox.FitContributor as FitContributor;


class Point {
    var x;
    var y;
}

class HikeField extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new HikeView();
        return [ view ];
    }
}

class HikeView extends Ui.DataField {

    hidden const FONT_JUSTIFY = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    //hidden const FONT_HEADER = Graphics.FONT_XTINY;
    hidden const FONT_HEADER = Ui.loadResource(Rez.Fonts.roboto_20);
    hidden const FONT_VALUE = Graphics.FONT_NUMBER_MILD;
    hidden const FONT_VALUE_SMALLER = FONT_HEADER;
    hidden const ZERO_TIME = "0:00";
    hidden const ZERO_DISTANCE = "0.00";

    hidden const STEPS_FIELD_ID = 0;
    hidden const STEPS_LAP_FIELD_ID = 1;

    var totalStepsField;
    var lapStepsField;

    hidden var kmOrMileInMeters = 1000;
    hidden var mOrFeetsInMeter = 1;
    hidden var is24Hour = true;

    //colors
    hidden var distanceUnits = System.UNIT_METRIC;
    hidden var elevationUnits = System.UNIT_METRIC;
    hidden var textColor = Graphics.COLOR_BLACK;
    hidden var inverseTextColor = Graphics.COLOR_WHITE;
    hidden var backgroundColor = Graphics.COLOR_WHITE;
    hidden var inverseBackgroundColor = Graphics.COLOR_BLACK;
    hidden var inactiveGpsBackground = Graphics.COLOR_LT_GRAY;
    hidden var batteryBackground = Graphics.COLOR_WHITE;
    hidden var batteryColor1 = Graphics.COLOR_GREEN;
    hidden var hrColor = Graphics.COLOR_RED;
    hidden var headerColor = Graphics.COLOR_DK_GRAY;

    //strings
    hidden var durationStr, distanceStr, cadenceStr, hrStr, stepsStr, speedStr, elevationStr, ascentStr, notificationStr;

    //data
    hidden var elapsedTime= 0;
    hidden var distance = 0;
    hidden var cadence = 0;
    hidden var hr = 0;
    hidden var elevation = 0;
    hidden var maxelevation = -65536;
    hidden var speed = 0;
    hidden var ascent = 0;
    hidden var descent = 0;
    hidden var gpsSignal = 0;
    hidden var stepPrev = 0;
    hidden var stepCount = 0;
    hidden var stepPrevLap = 0;
    hidden var stepsPerLap = [];
    hidden var startTime = [];
    hidden var stepsAddedToField = 0;

    hidden var checkStorage = false;

    hidden var phoneConnected = false;
    hidden var notificationCount = 0;

    hidden var hasBackgroundColorOption = false;

    hidden var doUpdates = 0;
    hidden var activityRunning = false;

    hidden var dcWidth = 0;
    hidden var dcHeight = 0;

    hidden var durationPoint = new Point();
    hidden var distancePoint = new Point();
    hidden var cadencePoint = new Point();
    hidden var hrPoint = new Point();
    hidden var stepsPoint = new Point();
    hidden var elevationPoint = new Point();
    hidden var ascentPoint = new Point();
    hidden var topBarHeight;
    hidden var bottomBarHeight;
    hidden var firstRowOffset;
    hidden var secondRowOffset;
    hidden var lineUp;
    hidden var lineUpSides;
    hidden var lineDown;
    hidden var lineDownSides;

    hidden var settingsUnlockCode = Application.getApp().getProperty("unlockCode");
    hidden var settingsShowCadence = Application.getApp().getProperty("showCadence");
    hidden var settingsShowHR = Application.getApp().getProperty("showHR");
    //hidden var settingsShowHRZone = Application.getApp().getProperty("showHRZone");
    hidden var settingsMaxElevation = Application.getApp().getProperty("showMaxElevation");
    hidden var settingsNotification = Application.getApp().getProperty("showNotification");
    hidden var settingsAvaiable = false;

    function checkUnlockCode(code) {
        code = "325b1f2c8d05cf7a1e83";
        var uuid = System.getDeviceSettings().uniqueIdentifier;
        var secret = "jtymejczykgarminasia";
        var calculated = "";


        System.println(code);
        System.println(uuid);
        System.println(secret);

        return calculated.equals(code);
    }

    function initialize() {
        DataField.initialize();

        totalStepsField = createField(
            Ui.loadResource(Rez.Strings.steps_label),
            STEPS_FIELD_ID,
            FitContributor.DATA_TYPE_UINT32,
            {:mesgType=>FitContributor.MESG_TYPE_SESSION , :units=>Ui.loadResource(Rez.Strings.steps_unit)}
        );

        lapStepsField = createField(
            Ui.loadResource(Rez.Strings.steps_label),
            STEPS_LAP_FIELD_ID,
            FitContributor.DATA_TYPE_UINT32,
            {:mesgType=>FitContributor.MESG_TYPE_LAP , :units=>Ui.loadResource(Rez.Strings.steps_unit)}
        );

        Application.getApp().setProperty("uuid", System.getDeviceSettings().uniqueIdentifier);

        if (checkUnlockCode(settingsUnlockCode)) {
            settingsAvaiable = true;
        }
    }

    function compute(info) {
        var mySettings = System.getDeviceSettings();

        elapsedTime = info.timerTime != null ? info.timerTime : 0;
        hr = info.currentHeartRate != null ? info.currentHeartRate : 0;
        distance = info.elapsedDistance != null ? info.elapsedDistance : 0;
        gpsSignal = info.currentLocationAccuracy != null ? info.currentLocationAccuracy : 0;
        cadence = info.currentCadence != null ? info.currentCadence : 0;
        speed = info.currentSpeed != null ? info.currentSpeed : 0;
        ascent = info.totalAscent != null ? info.totalAscent : 0;
        descent = info.totalDescent != null ? info.totalDescent : 0;
        elevation = info.altitude != null ? info.altitude : 0;

        if (stepsAddedToField < stepsPerLap.size() * 2) {
            if (stepsAddedToField & 0x1) {
                lapStepsField.setData(stepsPerLap[stepsAddedToField / 2]);
            }
            stepsAddedToField++;
        }

        if (activityRunning) {
            if (checkStorage && Activity.getActivityInfo().startTime != null) {
                checkStorage = false;
                checkValues();
            }
            var stepCur = ActivityMonitor.getInfo().steps;
            if (stepCur < stepPrev) {
                stepCount = stepCount + stepCur;
                stepPrev = stepCur;
            } else {
                stepCount = stepCount + stepCur - stepPrev;
                stepPrev = stepCur;
            }
        }

        if (elevation > maxelevation) {
            maxelevation = elevation;
        }

        phoneConnected = mySettings.phoneConnected;
        if (phoneConnected) {
            notificationCount = mySettings.notificationCount;
        }
    }

    function onLayout(dc) {
        setDeviceSettingsDependentVariables();
        dcHeight = dc.getHeight();
        dcWidth = dc.getWidth();
        topBarHeight = 30;
        bottomBarHeight = 42;
        firstRowOffset = 10;
        secondRowOffset = 38 - (240 - dcHeight) / 4;
        durationPoint.x = 69 - (240 - dcWidth) / 2;
        durationPoint.y = topBarHeight;
        distancePoint.x = dcWidth - 69 + (240 - dcWidth) / 2;
        distancePoint.y = topBarHeight;
        cadencePoint.x = 44;
        cadencePoint.y = topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 3;
        hrPoint.x = dcWidth / 2;
        hrPoint.y = topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 3;
        stepsPoint.x = dcWidth - 44;
        stepsPoint.y = topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 3;
        elevationPoint.x = 65;
        elevationPoint.y = topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 3 * 2;
        ascentPoint.x = dcWidth - 65;
        ascentPoint.y = topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 3 * 2;
        lineUpSides = 15 + (240 - dcWidth) / 4;
        lineDownSides = 15 + (240 - dcWidth) / 3;
    }

    function onShow() {
        doUpdates = true;
        return true;
    }

    function onHide() {
        doUpdates = false;
    }

    function onUpdate(dc) {
        if(doUpdates == false) {
            return;
        }

        setColors();
        dc.clear();
        dc.setColor(backgroundColor, backgroundColor);
        dc.fillRectangle(0, 0, dcWidth, dcHeight);

        drawValues(dc);
    }

    function checkValues() {
        var savedStartTime = null;
        startTime = Activity.getActivityInfo().startTime;
        savedStartTime = Storage.getValue("startTime");
        if (savedStartTime != null && startTime != null && startTime.value() == savedStartTime) {
            stepCount = Storage.getValue("totalSteps");
            stepsPerLap = Storage.getValue("stepsPerLap");
            if (stepsPerLap.size() > 0) {
                stepPrevLap = stepsPerLap[stepsPerLap.size() - 1];
            }
        }
    }

    function onTimerStart() {
        activityRunning = true;
        stepPrev = ActivityMonitor.getInfo().steps;
        checkStorage = true;
    }

    function onTimerResume() {
        activityRunning = true;
        stepPrev = ActivityMonitor.getInfo().steps;
    }

    function onTimerPause() {
        activityRunning = false;
    }

    function onTimerStop() {
        var sum = 0;
        Storage.setValue("startTime", Activity.getActivityInfo().startTime.value());
        Storage.setValue("totalSteps", stepCount);
        Storage.setValue("stepsPerLap", stepsPerLap);
        activityRunning = false;
        totalStepsField.setData(stepCount);
        for (var i = 0; i < stepsPerLap.size(); i++) {
            sum += stepsPerLap[i];
        }
        lapStepsField.setData(stepCount - sum);
    }

    function onTimerLap() {
        stepsPerLap.add(stepCount - stepPrevLap);
        stepPrevLap = stepCount;
    }

    function setDeviceSettingsDependentVariables() {
        hasBackgroundColorOption = (self has :getBackgroundColor);

        distanceUnits = System.getDeviceSettings().distanceUnits;
        if (distanceUnits == System.UNIT_METRIC) {
            kmOrMileInMeters = 1000;
        } else {
            kmOrMileInMeters = 1609.344;
        }

        elevationUnits = System.getDeviceSettings().elevationUnits;
        if (elevationUnits == System.UNIT_METRIC) {
            mOrFeetsInMeter = 1;
        } else {
            mOrFeetsInMeter = 3.2808399;
        }
        is24Hour = System.getDeviceSettings().is24Hour;

        hrStr = Ui.loadResource(Rez.Strings.hr);
        distanceStr = Ui.loadResource(Rez.Strings.distance);
        durationStr = Ui.loadResource(Rez.Strings.duration);
        cadenceStr = Ui.loadResource(Rez.Strings.cadence);
        stepsStr = Ui.loadResource(Rez.Strings.steps);
        speedStr = Ui.loadResource(Rez.Strings.speed);
        elevationStr = Ui.loadResource(Rez.Strings.elevation);
    }

    function setColors() {
        if (hasBackgroundColorOption) {
            backgroundColor = getBackgroundColor();
            textColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            inverseTextColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_WHITE;
            inverseBackgroundColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLACK: Graphics.COLOR_BLACK;
            hrColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLUE : Graphics.COLOR_RED;
            headerColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_LT_GRAY: Graphics.COLOR_DK_GRAY;
            batteryColor1 = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GREEN;
        }
    }

    function drawValues(dc) {

        //Time
        var clockTime = System.getClockTime();
        var time;
        if (is24Hour) {
            time = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%.2d")]);
        } else {
            time = Lang.format("$1$:$2$", [computeHour(clockTime.hour), clockTime.min.format("%.2d")]);
            time += (clockTime.hour < 12) ? " am" : " pm";
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, 0, dcWidth, topBarHeight);
        dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dcWidth / 2, topBarHeight / 2, Graphics.FONT_MEDIUM, time, FONT_JUSTIFY);

        //Battery and gps
        dc.setColor(inverseBackgroundColor, inverseBackgroundColor);
        dc.fillRectangle(0, dcHeight - bottomBarHeight, dcWidth, bottomBarHeight);

        drawBattery(System.getSystemStats().battery, dc, dcWidth / 2 - 50, dcHeight - 32, 28, 17); //todo

        if (gpsSignal < 2) {
            drawGpsSign(dc, dcWidth / 2 + 24, dcHeight - 35, inactiveGpsBackground, inactiveGpsBackground, inactiveGpsBackground); //todo
        } else if (gpsSignal == 2) {
            drawGpsSign(dc, dcWidth / 2 + 24, dcHeight - 35, batteryColor1, inactiveGpsBackground, inactiveGpsBackground);
        } else if (gpsSignal == 3) {
            drawGpsSign(dc, dcWidth / 2 + 24, dcHeight - 35, batteryColor1, batteryColor1, inactiveGpsBackground);
        } else {
            drawGpsSign(dc, dcWidth / 2 + 24, dcHeight - 35, batteryColor1, batteryColor1, batteryColor1);
        }

        if (!(settingsAvaiable && !settingsNotification)) {
            if (phoneConnected) {
                notificationStr = notificationCount.format("%d");
            } else {
                notificationStr = "-";
            }

            dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dcWidth / 2, dcHeight - 25, Graphics.FONT_MEDIUM, notificationStr, FONT_JUSTIFY);
        }

        //Grid
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, topBarHeight, dcWidth, topBarHeight);
        dc.drawLine(0, dcHeight - bottomBarHeight, dcWidth, dcHeight - bottomBarHeight);
        dc.drawLine(0, cadencePoint.y, dcWidth / 2 - lineUpSides, cadencePoint.y);
        dc.drawLine(dcWidth, cadencePoint.y, dcWidth / 2 + lineUpSides, cadencePoint.y);
        dc.drawLine(0, elevationPoint.y, dcWidth / 2 - lineDownSides, elevationPoint.y);
        dc.drawLine(dcWidth, elevationPoint.y, dcWidth / 2 + lineDownSides, elevationPoint.y);
        dc.drawLine(dcWidth / 2, topBarHeight, dcWidth / 2, topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 2 - 32);
        dc.drawLine(dcWidth / 2, dcHeight - bottomBarHeight - 1, dcWidth / 2, topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 2 + 32);

        if (!(settingsAvaiable && !settingsShowHR)) {
            dc.drawCircle(dcWidth / 2, topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 2, 32);
        } else {
            dc.drawLine(dcWidth / 2 - lineUpSides, cadencePoint.y, dcWidth / 2 + lineUpSides, cadencePoint.y);
            dc.drawLine(dcWidth / 2 - lineUpSides, elevationPoint.y, dcWidth / 2 + lineUpSides, elevationPoint.y);
            dc.drawLine(dcWidth / 2, topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 2 - 32, dcWidth / 2, topBarHeight + (dcHeight - topBarHeight - bottomBarHeight) / 2 + 32);
        }

        dc.setPenWidth(1);

        //Duration
        var duration;
        if (elapsedTime != null && elapsedTime > 0) {
            var hours = null;
            var minutes = elapsedTime / 1000 / 60;
            var seconds = elapsedTime / 1000 % 60;

            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
            }

            if (hours == null) {
                duration = minutes.format("%d") + ":" + seconds.format("%02d");
            } else {
                duration = hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
            }
        } else {
            duration = ZERO_TIME;
        }
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(durationPoint.x, durationPoint.y + firstRowOffset, FONT_HEADER, durationStr, FONT_JUSTIFY);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(durationPoint.x, durationPoint.y + secondRowOffset, FONT_VALUE, duration, FONT_JUSTIFY);

        //Distance
        var distStr;
        if (distance > 0) {
            var distanceKmOrMiles = distance / kmOrMileInMeters;
            if (distanceKmOrMiles < 100) {
                distStr = distanceKmOrMiles.format("%.2f");
            } else {
                distStr = distanceKmOrMiles.format("%.1f");
            }
        } else {
            distStr = ZERO_DISTANCE;
        }
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(distancePoint.x , distancePoint.y + firstRowOffset, FONT_HEADER, distanceStr, FONT_JUSTIFY);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(distancePoint.x, distancePoint.y + secondRowOffset, FONT_VALUE, distStr, FONT_JUSTIFY);

        //Speed + cadence
        speed = speed * 3600 / kmOrMileInMeters;
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        if (!(settingsAvaiable && !settingsShowCadence)) {
            dc.drawText(cadencePoint.x - 15, cadencePoint.y + firstRowOffset, FONT_VALUE_SMALLER, cadence, FONT_JUSTIFY);
        } else {
            dc.drawText(cadencePoint.x - 15, cadencePoint.y + firstRowOffset, FONT_VALUE_SMALLER, speedStr, FONT_JUSTIFY);
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cadencePoint.x, cadencePoint.y + secondRowOffset, FONT_VALUE, speed.format("%.1f"), FONT_JUSTIFY);

        //HR
        if (!(settingsAvaiable && !settingsShowHR)) {
            dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hrPoint.x, hrPoint.y + firstRowOffset, FONT_HEADER, hrStr, FONT_JUSTIFY);
            dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hrPoint.x, hrPoint.y + secondRowOffset, FONT_VALUE, hr.format("%d"), FONT_JUSTIFY);
        }

        //Steps
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(stepsPoint.x, stepsPoint.y + firstRowOffset, FONT_HEADER, stepsStr, FONT_JUSTIFY);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(stepsPoint.x, stepsPoint.y + secondRowOffset, FONT_VALUE, stepCount, FONT_JUSTIFY);

        //Elevation
        var elevationmOrFeets = elevation * mOrFeetsInMeter;
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        if (!(settingsAvaiable && !settingsMaxElevation)) {
            var maxelevationmOrFeets = maxelevation * mOrFeetsInMeter;
            dc.drawText(elevationPoint.x , elevationPoint.y + firstRowOffset, FONT_HEADER, maxelevationmOrFeets.format("%.0f"), FONT_JUSTIFY);
        } else {
            dc.drawText(elevationPoint.x , elevationPoint.y + firstRowOffset, FONT_HEADER, elevationStr, FONT_JUSTIFY);
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(elevationPoint.x, elevationPoint.y + secondRowOffset, FONT_VALUE, elevationmOrFeets.format("%.0f"), FONT_JUSTIFY);

        //Ascent
        var descentnmOrFeets = descent * mOrFeetsInMeter;
        var ascentnmOrFeets = ascent * mOrFeetsInMeter;
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ascentPoint.x , ascentPoint.y + firstRowOffset, FONT_HEADER, descentnmOrFeets.format("%.0f"), FONT_JUSTIFY);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ascentPoint.x, ascentPoint.y + secondRowOffset, FONT_VALUE, ascentnmOrFeets.format("%.0f"), FONT_JUSTIFY);

    }

    function drawBattery(battery, dc, xStart, yStart, width, height) {
        dc.setColor(batteryBackground, inactiveGpsBackground);
        dc.fillRectangle(xStart, yStart, width, height);
        if (battery < 10) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(xStart+3 + width / 2, yStart + 7, FONT_HEADER, format("$1$%", [battery.format("%d")]), FONT_JUSTIFY);
        }

        if (battery < 10) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else if (battery < 30) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(batteryColor1, Graphics.COLOR_TRANSPARENT);
        }
        dc.fillRectangle(xStart + 1, yStart + 1, (width-2) * battery / 100, height - 2);

        dc.setColor(batteryBackground, batteryBackground);
        dc.fillRectangle(xStart + width - 1, yStart + 3, 4, height - 6);
    }

    function drawGpsSign(dc, xStart, yStart, color1, color2, color3) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(xStart - 1, yStart + 11, 8, 10);
        dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart, yStart + 12, 6, 8);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(xStart + 6, yStart + 7, 8, 14);
        dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart + 7, yStart + 8, 6, 12);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(xStart + 13, yStart + 3, 8, 18);
        dc.setColor(color3, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart + 14, yStart + 4, 6, 16);
    }

    function computeHour(hour) {
        if (hour < 1) {
            return hour + 12;
        }
        if (hour >  12) {
            return hour - 12;
        }
        return hour;
    }
}
