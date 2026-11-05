class RscText
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = 0;
    idc = -1;
    colorBackground[] = {0, 0, 0, 0};
    colorText[] = {1, 1, 1, 1};
    text = "";
    fixedWidth = 0;
    x = 0;
    y = 0;
    h = 0.037;
    w = 0.3;
    style = 0;
    shadow = 1;
    colorShadow[] = {0, 0, 0, 0.5};
    font = "RobotoCondensed";
    SizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    linespacing = 1;
    tooltipColorBox[] = {1, 1, 1, 1};
    tooltipColorText[] = {1, 1, 1, 1};
    tooltipColorColor[] = {0, 0, 0, 1};
};

class RscStructuredText
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = 13;
    idc = -1;
    style = 0;
    colorText[] = {1,1,1,1};
    class Attributes
    {
        font = "RobotoCondensed";
        color = "#ffffff";
        align = "left";
        shadow = 1;
    };
    x = 0;
    y = 0;
    h = 0.035;
    w = 0.1;
    text = "";
    size = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    shadow = 1;
};

class RscCheckBox
{
    idc = -1;
    type = 77;
    style = 0;
    checked = 0;
    x = "0.375 * safezoneW + safezoneX";
    y = "0.36 * safezoneH + safezoneY";
    w = "0.025 * safezoneW";
    h = "0.04 * safezoneH";
    color[] = {1, 1, 1, 0.7};
    colorFocused[] = {1, 1, 1, 1};
    colorHover[] = {1, 1, 1, 1};
    colorPressed[] = {1, 1, 1, 1};
    colorDisabled[] = {1, 1, 1, 0.2};
    colorBackground[] = {0, 0, 0, 0};
    colorBackgroundFocused[] = {0, 0, 0, 0};
    colorBackgroundHover[] = {0, 0, 0, 0};
    colorBackgroundPressed[] = {0, 0, 0, 0};
    colorBackgroundDisabled[] = {0, 0, 0, 0};
    textureChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
    textureUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
    textureFocusedChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
    textureFocusedUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
    textureHoverChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
    textureHoverUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
    texturePressedChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
    texturePressedUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
    textureDisabledChecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_checked_ca.paa";
    textureDisabledUnchecked = "\A3\Ui_f\data\GUI\RscCommon\RscCheckBox\CheckBox_unchecked_ca.paa";
    tooltipColorText[] = {1, 1, 1, 1};
    tooltipColorBox[] = {1, 1, 1, 1};
    tooltipColorShade[] = {0, 0, 0, 0.65};
    soundEnter[] = {"", 0.1, 1};
    soundPush[] = {"", 0.1, 1};
    soundClick[] = {"", 0.1, 1};
    soundEscape[] = {"", 0.1, 1};
};

class RscButton
{
    deletable = 0;
    fade = 0;
    type = 1;
    text = "";
    colorText[] = {1, 1, 1, 1};
    colorDisabled[] = {0.4, 0.4, 0.4, 1};
    colorBackground[] = {0.2, 0.2, 0.2, 1};
    colorBackgroundDisabled[] = {0.3, 0.3, 0.3, 1};
    colorBackgroundActive[] = {0.15, 0.35, 0.55, 1};
    colorFocused[] = {0.2, 0.5, 0.8, 1};
    colorShadow[] = {0, 0, 0, 0};
    colorBorder[] = {0, 0, 0, 1};
    soundEnter[] = {"\A3\ui_f\data\sound\RscButton\soundEnter", 0.09, 1};
    soundPush[] = {"\A3\ui_f\data\sound\RscButton\soundPush", 0.09, 1};
    soundClick[] = {"\A3\ui_f\data\sound\RscButton\soundClick", 0.09, 1};
    soundEscape[] = {"\A3\ui_f\data\sound\RscButton\soundEscape", 0.09, 1};
    idc = -1;
    style = 2;
    x = 0;
    y = 0;
    w = 0.095589;
    h = 0.039216;
    shadow = 2;
    font = "RobotoCondensed";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    url = "";
    offsetX = 0;
    offsetY = 0;
    offsetPressedX = 0;
    offsetPressedY = 0;
    borderSize = 0;
};

class RscCombo
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = 4;
    colorSelect[] = {0, 0, 0, 1};
    colorText[] = {1, 1, 1, 1};
    colorBackground[] = {0, 0, 0, 1};
    colorScrollbar[] = {1, 0, 0, 1};
    soundSelect[] = {"\A3\ui_f\data\sound\RscCombo\soundSelect", 0.1, 1};
    soundExpand[] = {"\A3\ui_f\data\sound\RscCombo\soundExpand", 0.1, 1};
    soundCollapse[] = {"\A3\ui_f\data\sound\RscCombo\soundCollapse", 0.1, 1};
    maxHistoryDelay = 1;
    class ComboScrollBar
    {
        color[] = {1, 1, 1, 1};
    };
    style = "0x10 + 0x200";
    font = "RobotoCondensed";
    sizeEx = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    shadow = 0;
    x = 0;
    y = 0;
    w = 0.12;
    h = 0.035;
    colorSelectBackground[] = {1, 1, 1, 0.7};
    arrowEmpty = "\A3\ui_f\data\GUI\RscCommon\rsccombo\arrow_combo_ca.paa";
    arrowFull = "\A3\ui_f\data\GUI\RscCommon\rsccombo\arrow_combo_active_ca.paa";
    wholeHeight = 0.45;
    colorActive[] = {1, 0, 0, 1};
    colorDisabled[] = {1, 1, 1, 0.25};
    tooltipColorText[] = {1, 1, 1, 1};
    tooltipColorBox[] = {1, 1, 1, 1};
    tooltipColorShade[] = {0, 0, 0, 0.65};
};

class RscPicture
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = 0;
    idc = -1;
    style = 48;
    colorBackground[] = {0, 0, 0, 0};
    colorText[] = {1, 1, 1, 1};
    font = "TahomaB";
    sizeEx = 0;
    lineSpacing = 0;
    text = "";
    fixedWidth = 0;
    shadow = 0;
    x = 0;
    y = 0;
    w = 0.2;
    h = 0.15;
    tooltipColorText[] = {1, 1, 1, 1};
    tooltipColorBox[] = {1, 1, 1, 1};
    tooltipColorShade[] = {0, 0, 0, 0.65};
};

class RscMapControl
{
    deletable = 0;
    fade = 0;
    access = 0;
    type = 101;
    idc = -1;
    style = 48;
    text = "#(argb,8,8,3)color(1,1,1,1)";
    colorBackground[] = {0.92, 0.90, 0.85, 1};
    colorOutside[] = {0.08, 0.12, 0.18, 1};
    colorText[] = {0, 0, 0, 1};
    font = "TahomaB";
    sizeEx = 0.04;
    fontLabel = "RobotoCondensed";
    sizeExLabel = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    fontGrid = "TahomaB";
    sizeExGrid = 0.02;
    fontUnits = "TahomaB";
    sizeExUnits = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    fontNames = "RobotoCondensed";
    sizeExNames = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8) * 2";
    fontInfo = "RobotoCondensed";
    sizeExInfo = "(((((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    fontLevel = "TahomaB";
    sizeExLevel = 0.02;
    colorSea[] = {0.35, 0.58, 0.82, 1};
    colorForest[] = {0.45, 0.68, 0.35, 1};
    colorRocks[] = {0.55, 0.55, 0.55, 1};
    colorCountlines[] = {0.572, 0.354, 0.188, 0.4};
    colorMainCountlines[] = {0.572, 0.354, 0.188, 0.7};
    colorCountlinesWater[] = {0.491, 0.577, 0.702, 0.5};
    colorMainCountlinesWater[] = {0.491, 0.577, 0.702, 0.8};
    colorForestBorder[] = {0.4, 0.6, 0.3, 1};
    colorRocksBorder[] = {0.4, 0.4, 0.4, 1};
    colorPowerLines[] = {0.1, 0.1, 0.1, 1};
    widthPowerLines = 4;
    colorRailWay[] = {0.8, 0.2, 0, 1};
    widthRailWay = 4;
    colorNames[] = {0.1, 0.1, 0.1, 0.9};
    colorInactive[] = {1, 1, 1, 0.5};
    colorLevels[] = {0.286, 0.177, 0.094, 0.5};
    colorTracks[] = {0.84, 0.76, 0.65, 0.4};
    colorRoads[] = {0.7, 0.7, 0.7, 1};
    colorMainRoads[] = {0.9, 0.5, 0.3, 1};
    colorTracksFill[] = {0.84, 0.76, 0.65, 1};
    colorRoadsFill[] = {1, 1, 1, 1};
    colorMainRoadsFill[] = {1, 0.6, 0.4, 1};
    colorGrid[] = {0.1, 0.1, 0.1, 0.6};
    colorGridMap[] = {0.1, 0.1, 0.1, 0.6};
    stickX[] = {0.2, {"Gamma", 1, 1.5}};
    stickY[] = {0.2, {"Gamma", 1, 1.5}};

    ptsPerSquareSea = 5;
    ptsPerSquareTxt = 3;
    ptsPerSquareCLn = 10;
    ptsPerSquareExp = 10;
    ptsPerSquareCost = 10;
    ptsPerSquareFor = 9;
    ptsPerSquareForEdge = 9;
    ptsPerSquareRoad = 6;
    ptsPerSquareObj = 9;
    showCountourInterval = 0;
    scaleMin = 0.001;
    scaleMax = 1.0;
    scaleDefault = 0.18;
    maxSatelliteAlpha = 0.95;
    alphaFadeStartScale = 2.0;
    alphaFadeEndScale = 2.0;
    class Legend
    {
        colorBackground[] = {1, 1, 1, 0.5};
        color[] = {0, 0, 0, 1};
        x = "SafeZoneX";
        y = "SafeZoneY";
        w = 0.34;
        h = 0.152;
        font = "RobotoCondensed";
        sizeEx = 0.02;
    };
    class ActiveMarker
    {
        color[] = {0.3, 0.1, 0.9, 1};
        size = 50;
    };
    class Command
    {
        color[] = {1, 1, 1, 1};
        icon = "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
        size = 18;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
    };
    class Task
    {
        taskNone = "#(argb,8,8,3)color(0,0,0,0)";
        taskCreated = "#(argb,8,8,3)color(0,0,0,0)";
        taskAssigned = "#(argb,8,8,3)color(0,0,0,0)";
        taskSucceeded = "#(argb,8,8,3)color(0,0,0,0)";
        taskFailed = "#(argb,8,8,3)color(0,0,0,0)";
        taskCanceled = "#(argb,8,8,3)color(0,0,0,0)";
        colorCreated[] = {1, 1, 1, 1};
        colorCanceled[] = {0.7, 0.7, 0.7, 1};
        colorDone[] = {0.7, 1, 0.3, 1};
        colorFailed[] = {1, 0.3, 0.2, 1};
        color[] = {"(profileNamespace getVariable ['IGUI_TEXT_RGB_R',0])", "(profileNamespace getVariable ['IGUI_TEXT_RGB_G',1])", "(profileNamespace getVariable ['IGUI_TEXT_RGB_B',1])", "(profileNamespace getVariable ['IGUI_TEXT_RGB_A',0.8])"};
        icon = "\A3\ui_f\data\map\mapcontrol\taskIcon_CA.paa";
        iconCreated = "\A3\ui_f\data\map\mapcontrol\taskIconCreated_CA.paa";
        iconCanceled = "\A3\ui_f\data\map\mapcontrol\taskIconCanceled_CA.paa";
        iconDone = "\A3\ui_f\data\map\mapcontrol\taskIconDone_CA.paa";
        iconFailed = "\A3\ui_f\data\map\mapcontrol\taskIconFailed_CA.paa";
        size = 27;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
    };
    class CustomMark
    {
        color[] = {0, 0, 0, 1};
        icon = "\a3\ui_f\data\map\mapcontrol\custommark_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
    };
    class Tree
    {
        color[] = {0.45, 0.64, 0.33, 0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        size = 12;
        importance = "0.9 * 16 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class SmallTree
    {
        color[] = {0.45, 0.64, 0.33, 0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        size = 12;
        importance = "0.6 * 12 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Bush
    {
        color[] = {0.45, 0.64, 0.33, 0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        size = "14/2";
        importance = "0.2 * 14 * 0.05 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Church
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\church_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Chapel
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\Chapel_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Cross
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\Cross_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Rock
    {
        color[] = {0.1, 0.1, 0.1, 0.8};
        icon = "\A3\ui_f\data\map\mapcontrol\rock_ca.paa";
        size = 12;
        importance = "0.5 * 12 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Bunker
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
        size = 14;
        importance = "1.5 * 14 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Fortress
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
        size = 16;
        importance = "2 * 16 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class Fountain
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\fountain_ca.paa";
        size = 11;
        importance = "1 * 12 * 0.05";
        coefMin = 0.25;
        coefMax = 4;
    };
    class ViewTower
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\viewtower_ca.paa";
        size = 16;
        importance = "2.5 * 16 * 0.05";
        coefMin = 0.5;
        coefMax = 4;
    };
    class Lighthouse
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\lighthouse_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Quay
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\quay_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Fuelstation
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\fuelstation_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Hospital
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\hospital_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class BusStop
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\busstop_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Transmitter
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\transmitter_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Stack
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\stack_ca.paa";
        size = 20;
        importance = "2 * 16 * 0.05";
        coefMin = 0.9;
        coefMax = 4;
    };
    class Ruin
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\ruin_ca.paa";
        size = 16;
        importance = "1.2 * 16 * 0.05";
        coefMin = 1;
        coefMax = 4;
    };
    class Tourism
    {
        color[] = {0, 0, 0, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\tourism_ca.paa";
        size = 16;
        importance = "1 * 16 * 0.05";
        coefMin = 0.7;
        coefMax = 4;
    };
    class Watertower
    {
        color[] = {1, 1, 1, 1};
        icon = "\A3\ui_f\data\map\mapcontrol\watertower_ca.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
    };
    class Waypoint
    {
        color[] = {0, 0, 0, 1};
        size = 24;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
        icon = "\a3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
    };
    class WaypointCompleted
    {
        color[] = {0, 0, 0, 1};
        size = 24;
        importance = 1;
        coefMin = 1;
        coefMax = 1;
        icon = "\a3\ui_f\data\map\mapcontrol\waypointcompleted_ca.paa";
    };
    class LineMarker
    {
        lineDistanceMin = 3e-005;
        lineLengthMin = 5;
        lineWidthThick = 0.014;
        lineWidthThin = 0.008;
        textureComboBoxColor = "#(argb,8,8,3)color(1,1,1,1)";
    };

    shadow = 0;
    moveOnEdges = 1;
    showMarkers = 1;
    idcMarkerColor = -1;
    idcMarkerIcon = -1;

    class power
    {
        icon = "\A3\ui_f\data\map\mapcontrol\power_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class powersolar
    {
        icon = "\A3\ui_f\data\map\mapcontrol\powersolar_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class powerwave
    {
        icon = "\A3\ui_f\data\map\mapcontrol\powerwave_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class powerwind
    {
        icon = "\A3\ui_f\data\map\mapcontrol\powerwind_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {1, 1, 1, 1};
    };
    class Shipwreck
    {
        icon = "\A3\ui_f\data\map\mapcontrol\Shipwreck_CA.paa";
        size = 24;
        importance = 1;
        coefMin = 0.85;
        coefMax = 1;
        color[] = {0, 0, 0, 1};
    };
};

// ============================================================================
// DIALOGUE MAÎTRE : PANNEAU DE DÉPART TACTIQUE (ORA - AIR FORCE)
// ============================================================================
class Refour_Main_Menu_Dialog
{
    idd = 7000;
    movingEnable = false;
    enableSimulation = true;

    class controlsBackground
    {
        class FullScreenBackground: RscText
        {
            idc = -1;
            x = safezoneX;
            y = safezoneY;
            w = safezoneW;
            h = safezoneH;
            colorBackground[] = {0.03, 0.05, 0.08, 0.97};
        };

        class TopHeaderBar: RscText
        {
            idc = -1;
            text = "$STR_ORA_MENU_TITLE";
            x = safezoneX;
            y = safezoneY;
            w = safezoneW;
            h = 0.055 * safezoneH;
            colorBackground[] = {0.08, 0.22, 0.40, 1};
            style = 0x02; // Center
            sizeEx = 0.038;
            font = "RobotoCondensedBold";
        };

        class LeftPanelBg: RscText
        {
            idc = -1;
            x = safezoneX + (0.015 * safezoneW);
            y = safezoneY + (0.075 * safezoneH);
            w = 0.31 * safezoneW;
            h = 0.81 * safezoneH;
            colorBackground[] = {0.07, 0.09, 0.12, 0.88};
        };

        class MiddlePanelBg: RscText
        {
            idc = -1;
            x = safezoneX + (0.335 * safezoneW);
            y = safezoneY + (0.075 * safezoneH);
            w = 0.28 * safezoneW;
            h = 0.81 * safezoneH;
            colorBackground[] = {0.07, 0.09, 0.12, 0.88};
        };

        class RightPanelBg: RscText
        {
            idc = -1;
            x = safezoneX + (0.625 * safezoneW);
            y = safezoneY + (0.075 * safezoneH);
            w = 0.36 * safezoneW;
            h = 0.81 * safezoneH;
            colorBackground[] = {0.07, 0.09, 0.12, 0.88};
        };
    };

    class controls
    {
        // ====================================================================
        // COLONNE GAUCHE : OBJECTIFS PRINCIPAUX & CONFIGURATION DE SORTIE
        // ====================================================================
        class HeaderObjectives: RscText
        {
            idc = -1;
            text = "$STR_ORA_HEADER_OBJECTIVES";
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.09 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.028 * safezoneH;
            colorBackground[] = {0.12, 0.28, 0.48, 1};
            font = "RobotoCondensedBold";
        };

        // --- OBJECTIFS PRINCIPAUX OBLIGATOIRES (COCHES & BLOQUES) ---
        class CB_Obj1: RscCheckBox {
            idc = 7100;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.125 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Obj1: RscText {
            idc = -1;
            text = "$STR_ORA_TASK_PROTECT_RACS";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.125 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
            colorText[] = {0.85, 0.85, 0.85, 1};
        };

        class CB_Obj2: RscCheckBox {
            idc = 7101;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.153 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Obj2: RscText {
            idc = -1;
            text = "$STR_ORA_TASK_SURVIVE_RTB";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.153 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
            colorText[] = {0.85, 0.85, 0.85, 1};
        };

        class CB_Obj3: RscCheckBox {
            idc = 7102;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.181 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Obj3: RscText {
            idc = -1;
            text = "$STR_ORA_TASK_ZERO_CASUALTIES";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.181 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
            colorText[] = {0.85, 0.85, 0.85, 1};
        };

        class CB_Obj4: RscCheckBox {
            idc = 7103;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.209 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Obj4: RscText {
            idc = -1;
            text = "$STR_ORA_TASK_MAJORITY_SURVIVE";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.209 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
            colorText[] = {0.85, 0.85, 0.85, 1};
        };

        class Divider1: RscText {
            idc = -1;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.240 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.002 * safezoneH;
            colorBackground[] = {1, 1, 1, 0.15};
        };

        // --- CHOIX DU NOMBRE DE MISSIONS (EXCLUSIF : 1 SEUL CHOIX POSSIBLE) ---
        class HeaderMissionCount: RscText
        {
            idc = -1;
            text = "$STR_ORA_HEADER_MISSION_COUNT";
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.252 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.028 * safezoneH;
            colorBackground[] = {0.12, 0.28, 0.48, 1};
            font = "RobotoCondensedBold";
        };

        class CB_Count5: RscCheckBox {
            idc = 7110;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.290 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Count5: RscText {
            idc = -1;
            text = "$STR_ORA_COUNT_5";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.290 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
        };

        class CB_Count10: RscCheckBox {
            idc = 7111;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.318 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Count10: RscText {
            idc = -1;
            text = "$STR_ORA_COUNT_10";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.318 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
        };

        class CB_Count15: RscCheckBox {
            idc = 7112;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.346 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Count15: RscText {
            idc = -1;
            text = "$STR_ORA_COUNT_15";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.346 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
        };

        class CB_Count20: RscCheckBox {
            idc = 7113;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.374 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_Count20: RscText {
            idc = -1;
            text = "$STR_ORA_COUNT_20";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.374 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
        };

        class Divider2: RscText {
            idc = -1;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.408 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.002 * safezoneH;
            colorBackground[] = {1, 1, 1, 0.15};
        };

        // --- OPTIONS TACTIQUES DISPONIBLES ---
        class HeaderTacticalOptions: RscText
        {
            idc = -1;
            text = "$STR_ORA_HEADER_TACTICAL_OPTIONS";
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.420 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.028 * safezoneH;
            colorBackground[] = {0.12, 0.28, 0.48, 1};
            font = "RobotoCondensedBold";
        };

        // Option 1 : Téléguidage des tirs
        class CB_OptGuidance: RscCheckBox {
            idc = 7120;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.460 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_OptGuidance: RscText {
            idc = -1;
            text = "$STR_ORA_OPT_GUIDANCE";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.460 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
            colorText[] = {0.2, 0.85, 1, 1};
        };

        // Option 2 : Autres présences alliées
        class CB_OptAllies: RscCheckBox {
            idc = 7121;
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.490 * safezoneH);
            w = 0.014 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class Txt_OptAllies: RscText {
            idc = -1;
            text = "$STR_ORA_OPT_ALLIES";
            x = safezoneX + (0.045 * safezoneW);
            y = safezoneY + (0.490 * safezoneH);
            w = 0.265 * safezoneW;
            h = 0.022 * safezoneH;
            colorText[] = {0.2, 0.95, 0.4, 1};
        };

        // CONDITION DE DÉFAITE IMPÉRATIVE (AUCUNE CHECKBOX)
        class HeaderDefeatCondition: RscText {
            idc = -1;
            text = "$STR_ORA_HEADER_DEFEAT_CONDITION";
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.525 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.026 * safezoneH;
            colorBackground[] = {0.60, 0.10, 0.10, 1}; // Rouge vif de restriction
            colorText[] = {1, 1, 1, 1};
            font = "RobotoCondensedBold";
        };

        // Alerte explicative en rouge encadré
        class Box_NoEjectAlert: RscStructuredText {
            idc = 7130;
            text = "$STR_ORA_ALERT_NO_EJECT_INFO";
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.555 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.075 * safezoneH;
            colorBackground[] = {0.45, 0.05, 0.05, 0.85};
        };

        class Txt_Directives: RscStructuredText {
            idc = -1;
            text = "$STR_ORA_TACTICAL_DIRECTIVES_AIR";
            x = safezoneX + (0.025 * safezoneW);
            y = safezoneY + (0.640 * safezoneH);
            w = 0.29 * safezoneW;
            h = 0.220 * safezoneH;
            colorBackground[] = {0,0,0,0};
        };

        // ====================================================================
        // COLONNE CENTRALE : MÉTÉO & CAMÉRA 3D DE L'AVION (PLANE_0)
        // ====================================================================
        class EnvHeader: RscText
        {
            idc = -1;
            text = "$STR_LABEL_ENVIRONMENT";
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.09 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.028 * safezoneH;
            colorBackground[] = {0.12, 0.28, 0.48, 1};
            font = "RobotoCondensedBold";
        };

        class LabelTime: RscText
        {
            idc = -1;
            text = "$STR_LABEL_TIME";
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.125 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class ComboTime: RscCombo
        {
            idc = 7200;
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.150 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.030 * safezoneH;
            onLBSelChanged = "['UPDATE_ENV_PREVIEW', _this] spawn ORA_fnc_mainMenu;";
        };

        class LabelClouds: RscText
        {
            idc = -1;
            text = "$STR_LABEL_CLOUDS";
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.188 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class ComboClouds: RscCombo
        {
            idc = 7201;
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.213 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.030 * safezoneH;
            onLBSelChanged = "['UPDATE_ENV_PREVIEW', _this] spawn ORA_fnc_mainMenu;";
        };

        class LabelFog: RscText
        {
            idc = -1;
            text = "$STR_LABEL_FOG";
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.251 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.022 * safezoneH;
        };
        class ComboFog: RscCombo
        {
            idc = 7202;
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.276 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.030 * safezoneH;
            onLBSelChanged = "['UPDATE_ENV_PREVIEW', _this] spawn ORA_fnc_mainMenu;";
        };

        // APERÇU CAMÉRA 3D DE L'AVION (plane_0)
        class VehicleCameraHeader: RscText
        {
            idc = -1;
            text = "$STR_ORA_HEADER_AIRCRAFT_PREVIEW";
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.320 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.028 * safezoneH;
            colorBackground[] = {0.12, 0.28, 0.48, 1};
            font = "RobotoCondensedBold";
        };

        class VehicleCameraScreen: RscPicture
        {
            idc = 7203;
            text = "#(argb,512,512,1)r2t(rendertarget8,1.0)";
            x = safezoneX + (0.345 * safezoneW);
            y = safezoneY + (0.355 * safezoneH);
            w = 0.26 * safezoneW;
            h = 0.485 * safezoneH;
        };

        // ====================================================================
        // COLONNE DROITE : CARTE TACTIQUE EN GRAND (SAHRANI)
        // ====================================================================
        class TacticalHeader: RscText
        {
            idc = -1;
            text = "$STR_ORA_HEADER_THEATER_MAP";
            x = safezoneX + (0.635 * safezoneW);
            y = safezoneY + (0.09 * safezoneH);
            w = 0.34 * safezoneW;
            h = 0.028 * safezoneH;
            colorBackground[] = {0.12, 0.28, 0.48, 1};
            font = "RobotoCondensedBold";
        };

        class TacticalInfoText: RscStructuredText
        {
            idc = -1;
            text = "$STR_ORA_MAP_DYNAMIC_NOTICE";
            x = safezoneX + (0.635 * safezoneW);
            y = safezoneY + (0.125 * safezoneH);
            w = 0.34 * safezoneW;
            h = 0.045 * safezoneH;
            colorBackground[] = {0.05, 0.15, 0.25, 0.7};
        };

        class MapPreview: RscMapControl
        {
            idc = 7302;
            text = "#(argb,8,8,3)color(1,1,1,1)";
            x = safezoneX + (0.635 * safezoneW);
            y = safezoneY + (0.178 * safezoneH);
            w = 0.34 * safezoneW;
            h = 0.662 * safezoneH;
            showMarkers = 1;
            maxSatelliteAlpha = 0.95;
            alphaFadeStartScale = 2.0;
            alphaFadeEndScale = 2.0;
            widthRailWay = 4;
            widthPowerLines = 4;
            colorBackground[] = {0.92, 0.90, 0.85, 1};
            colorSea[] = {0.35, 0.58, 0.82, 1};
            colorForest[] = {0.45, 0.68, 0.35, 1};
            colorRocks[] = {0.55, 0.55, 0.55, 1};
        };

        // ====================================================================
        // BOUTON DE LANCEMENT DE SORTIE (EN BAS)
        // ====================================================================
        class ButtonLaunch: RscButton
        {
            idc = 7400;
            text = "$STR_ORA_BUTTON_LAUNCH_SORTIE";
            x = safezoneX + (0.38 * safezoneW);
            y = safezoneY + (0.90 * safezoneH);
            w = 0.24 * safezoneW;
            h = 0.065 * safezoneH;
            colorBackground[] = {0.12, 0.55, 0.22, 1};
            colorBackgroundActive[] = {0.18, 0.70, 0.30, 1};
            sizeEx = 0.038;
            font = "RobotoCondensedBold";
            action = "['LAUNCH'] call ORA_fnc_mainMenu;";
        };
    };
};
