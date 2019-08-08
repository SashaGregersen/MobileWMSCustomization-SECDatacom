codeunit 50089 "SEC MOB WMS Conf. Tools"
{


    // This codeunit contains helper functions to generate configuration elements for:
    // - Header fields
    // - Registration steps
    // 
    // The functions shows the different options the mobile device is capable of.
    // 
    // USE THE "ExampleCode" FUNCTION AS A PLACE TO COPY THE CALLS YOU NEED
    // THIS FUNCTION IS NOT INTENDED TO BE USED
    // 
    // ************* Step Configuration *****************
    // To add a step multiple functions must be called.
    // There are a lot of parameters that CAN be set, but in most cases only a few is needed.
    // All parameters are defined as global variables.
    // 
    // Two functions are used to set:
    // - The standard values relevant to all step types. This MUST be called. It initializes all values with default values.
    //   RC_Std_Parms(_Id,_Name,_Header,_Label,_HelpLabel)
    // 
    // - The extended values relevant to all step types. This CAN be called if needed. It overwrites the relevant default values.
    //   RC_Ext_Parms(_EanAi,_AutoForwardAfterScan,_Optional,_Visible,_LabelWidth);
    // 
    // After that you call the relevant function that creates the step you need.
    // - RC_List_TableData(XmlCDataSection,_DataTable,_DataKeyColumn,_DataDisplayColumn,_DefaultValue);
    // 
    // ************* Header Configuration *****************


    trigger OnRun();
    begin
    end;

    var
        MobXMLMgt: Codeunit "MOB XML Management";
        Id: Integer;
        Name: Text[50];
        Header: Text[100];
        Label: Text[100];
        LabelWidth: Integer;
        HelpLabel: Text[100];
        AutoForwardAfterScan: Boolean;
        Optional: Boolean;
        Visible: Boolean;
        ListValues: Text[1024];
        ListSeparator: Text[1];
        DataTable: Text[50];
        DataKeyColumn: Text[50];
        DataDisplayColumn: Text[50];
        LinkedElement: Integer;
        FilterColumn: Text[50];
        DefaultValue: Text[50];
        EanAi: Text[50];
        LIST_Txt: Label 'List', Locked = true;
        DATE_Txt: Label 'Date', Locked = true;
        DATETIME_Txt: Label 'DateTime', Locked = true;
        DECIMAL_Txt: Label 'Decimal', Locked = true;
        IMAGE_Txt: Label 'Image', Locked = true;
        IMAGECAPTURE_Txt: Label 'ImageCapture', Locked = true;
        SIGNATURE_Txt: Label 'Signature', Locked = true;
        INFORMATION_Txt: Label 'Information', Locked = true;
        MULTI_LINE_TEXT_Txt: Label 'MultiLineText', Locked = true;
        MULTI_SCAN_Txt: Label 'MultiScan', Locked = true;
        QUANTITY_BY_SCAN_Txt: Label 'QuantityByScan', Locked = true;
        RADIO_BUTTON_Txt: Label 'RadioButton', Locked = true;
        TEXT_Txt: Label 'Text', Locked = true;
        SUMMARY_Txt: Label 'Summary', Locked = true;
        WARN_Txt: Label 'Warn', Locked = true;
        Length: Integer;
        HelpLabelMaximize: Boolean;
        ValidationValues: Text[1024];
        ValidationCaseSensitive: Boolean;
        Editable: Boolean;
        MinValue: Decimal;
        MaxValue: Decimal;
        OverDeliveryValidation: Text[10];
        UniqueValues: Boolean;
        ResolutionHeight: Integer;
        ResolutionWidth: Integer;
        PerformCalculation: Boolean;
        DateFormat: Text[50];
        MinDate: Date;
        MaxDate: Date;
        PrimaryInputMethod: Text[50];

    local procedure RC_Step_CData(var XmlCDataSection: XmlCData; InputType: Text[50]);
    begin
        // This function is private and should not be called from outside the codeunit

        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, '<add');
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' inputType="%1"', InputType));
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' id="%1"', Id));
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' name="%1"', Name));
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' header="%1"', Header));
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' label="%1"', Label));
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' labelWidth="%1"', LabelWidth));
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' helpLabel="%1"', HelpLabel));

        // For character based input fields the maximum allowed length can be set
        if Length <> -1 then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' length="%1"', Length));

        // Determines if the mobile device automatically moves on to the next step if a value is scanned
        // If it is set to false the mobile device stays on the step until the user manually moves forward
        if AutoForwardAfterScan then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' autoForwardAfterScan="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' autoForwardAfterScan="%1"', 'false'));

        // Determines if the step can be left blank / skipped or if the user must enter a value
        if Optional then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' optional="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' optional="%1"', 'false'));

        // Determines if the step is shown to the user
        if Visible then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' visible="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' visible="%1"', 'false'));

        if ListValues <> '' then begin
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' listValues="%1"', ListValues));

            // The separator is only relevant if list values are provided
            // Use ';' unless the caller defines another separator character
            if ListSeparator <> '' then
                MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' listSeparator="%1"', ListSeparator))
            else
                MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' listSeparator="%1"', ';'));
        end;

        if DataTable <> '' then begin
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' dataTable="%1"', DataTable));
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' dataKeyColumn="%1"', DataKeyColumn));
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' dataDisplayColumn="%1"', DataDisplayColumn));
        end;

        if LinkedElement <> -1 then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' linkedElement="%1"', LinkedElement));

        if FilterColumn <> '' then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' filterColumn="%1"', FilterColumn));

        // Use the default value to pre-populate the step with a value
        if DefaultValue <> '' then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' defaultValue="%1"', DefaultValue));

        // One or more GS1 application identifiers can be associated with a step
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' eanAi="%1"', EanAi));

        // Perform Calculation
        if PerformCalculation then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' performCalculation="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' performCalculation="%1"', 'false'));

        // Help Label Maximize
        if HelpLabelMaximize then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' helpLabelMaximize="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' helpLabelMaximize="%1"', 'false'));

        // Validation Values
        if ValidationValues <> '' then begin
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' validationValues="%1"', ValidationValues));

            // Case sensitive
            if ValidationCaseSensitive then
                MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' validationCaseSensitive="%1"', 'true'))
            else
                MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' validationCaseSensitive="%1"', 'false'));
        end;

        // Overdelivery Validation
        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' overDeliveryValidation="%1"', OverDeliveryValidation));

        // Editable
        if Editable then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' editable="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' editable="%1"', 'false'));

        // Unique values
        if UniqueValues then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' uniqueValues="%1"', 'true'))
        else
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' uniqueValues="%1"', 'false'));

        // Resolution Height
        if ResolutionHeight <> -1 then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' resolutionHeight="%1"', ResolutionHeight));

        // Resolution Width
        if ResolutionWidth <> -1 then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' resolutionWidth="%1"', ResolutionWidth));

        // Date Format
        if DateFormat <> '' then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' format="%1"', DateFormat));

        // Min Date
        if MinDate <> 0D then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' minDate="%1"', FORMAT(MinDate, 0, '<Day>-<Month>-<Year4>')));

        // Max Date
        if MaxDate <> 0D then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' maxDate="%1"', FORMAT(MaxDate, 0, '<Day>-<Month>-<Year4>')));

        // Min Value
        if MinValue <> -10000000 then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' minValue="%1"', MinValue));

        // Max Value
        if MaxValue <> 10000000 then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' maxValue="%1"', MaxValue));

        if PrimaryInputMethod <> '' then
            MobXMLMgt.NodeAppendCDataText(XmlCDataSection, STRSUBSTNO(' primaryInputMethod="%1"', PrimaryInputMethod));

        MobXMLMgt.NodeAppendCDataText(XmlCDataSection, '/>');
    end;

    local procedure RC_Step_XmlNode(var XMLSteps: XmlNode; InputType: Text[50]; ShowUnique: Boolean);
    var
        MobXMLMgt: Codeunit "MOB XML Management";
        XMLAddElement: XmlNode;
    begin
        // This function is private and should not be called outside this codeunit

        MobXMLMgt.AddElement(XMLSteps, 'add', '', MobXMLMgt.GetNodeNSURI(XMLSteps), XMLAddElement);
        MobXMLMgt.AddAttribute(XMLAddElement, 'inputType', InputType);
        MobXMLMgt.AddAttribute(XMLAddElement, 'id', FORMAT(Id, 0, 9));
        MobXMLMgt.AddAttribute(XMLAddElement, 'name', Name);
        MobXMLMgt.AddAttribute(XMLAddElement, 'header', Header);
        MobXMLMgt.AddAttribute(XMLAddElement, 'label', Label);
        MobXMLMgt.AddAttribute(XMLAddElement, 'labelWidth', FORMAT(LabelWidth, 0, 9));
        MobXMLMgt.AddAttribute(XMLAddElement, 'helpLabel', HelpLabel);

        // For character based input fields the maximum allowed length can be set
        if Length <> -1 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'length', FORMAT(Length, 0, 9));

        // Determines if the mobile device automatically moves on to the next step if a value is scanned
        // If it is set to false the mobile device stays on the step until the user manually moves forward
        if AutoForwardAfterScan then
            MobXMLMgt.AddAttribute(XMLAddElement, 'autoForwardAfterScan', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'autoForwardAfterScan', 'false');

        // Determines if the step can be left blank / skipped or if the user must enter a value
        if Optional then
            MobXMLMgt.AddAttribute(XMLAddElement, 'optional', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'optional', 'false');

        // Determines if the step is shown to the user
        if Visible then
            MobXMLMgt.AddAttribute(XMLAddElement, 'visible', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'visible', 'false');

        if ListValues <> '' then begin
            MobXMLMgt.AddAttribute(XMLAddElement, 'listValues', ListValues);

            // The separator is only relevant if list values are provided
            // Use ';' unless the caller defines another separator character
            if ListSeparator <> '' then
                MobXMLMgt.AddAttribute(XMLAddElement, 'listSeparator', ListSeparator)
            else
                MobXMLMgt.AddAttribute(XMLAddElement, 'listSeparator', ';');
        end;

        if DataTable <> '' then begin
            MobXMLMgt.AddAttribute(XMLAddElement, 'dataTable', DataTable);
            MobXMLMgt.AddAttribute(XMLAddElement, 'dataKeyColumn', DataKeyColumn);
            MobXMLMgt.AddAttribute(XMLAddElement, 'dataDisplayColumn', DataDisplayColumn);
        end;

        if LinkedElement <> -1 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'linkedElement', FORMAT(LinkedElement, 0, 9));

        if FilterColumn <> '' then
            MobXMLMgt.AddAttribute(XMLAddElement, 'filterColumn', FilterColumn);

        // Use the default value to pre-populate the step with a value
        if DefaultValue <> '' then
            MobXMLMgt.AddAttribute(XMLAddElement, 'defaultValue', DefaultValue);

        // One or more GS1 application identifiers can be associated with a step
        MobXMLMgt.AddAttribute(XMLAddElement, 'eanAi', EanAi);

        // Perform Calculation
        if PerformCalculation then
            MobXMLMgt.AddAttribute(XMLAddElement, 'performCalculation', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'performCalculation', 'false');

        // Help Label Maximize
        if HelpLabelMaximize then
            MobXMLMgt.AddAttribute(XMLAddElement, 'helpLabelMaximize', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'helpLabelMaximize', 'false');

        // Validation Values
        if ValidationValues <> '' then begin
            MobXMLMgt.AddAttribute(XMLAddElement, 'validationValues', ValidationValues);

            // Case sensitive
            if ValidationCaseSensitive then
                MobXMLMgt.AddAttribute(XMLAddElement, 'validationCaseSensitive', 'true')
            else
                MobXMLMgt.AddAttribute(XMLAddElement, 'validationCaseSensitive', 'false');
        end;

        // Overdelivery Validation
        MobXMLMgt.AddAttribute(XMLAddElement, 'overDeliveryValidation', OverDeliveryValidation);

        // Editable
        if Editable then
            MobXMLMgt.AddAttribute(XMLAddElement, 'editable', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'editable', 'false');

        // Unique values
        if ShowUnique then
            if UniqueValues then
                MobXMLMgt.AddAttribute(XMLAddElement, 'uniqueValues', 'true')
            else
                MobXMLMgt.AddAttribute(XMLAddElement, 'uniqueValues', 'false');

        // Resolution Height
        if ResolutionHeight <> -1 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'resolutionHeight', FORMAT(ResolutionHeight, 0, 9));

        // Resolution Width
        if ResolutionWidth <> -1 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'resolutionWidth', FORMAT(ResolutionWidth, 0, 9));

        // Date Format
        if DateFormat <> '' then
            MobXMLMgt.AddAttribute(XMLAddElement, 'format', DateFormat);

        // Min Date
        if MinDate <> 0D then
            MobXMLMgt.AddAttribute(XMLAddElement, 'minDate', FORMAT(MinDate, 0, '<Day>-<Month>-<Year4>'));

        // Max Date
        if MaxDate <> 0D then
            MobXMLMgt.AddAttribute(XMLAddElement, 'maxDate', FORMAT(MaxDate, 0, '<Day>-<Month>-<Year4>'));

        // Min Value
        if MinValue <> -10000000 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'minValue', FORMAT(MinValue, 0, 9));

        // Max Value
        if MaxValue <> 10000000 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'maxValue', FORMAT(MaxValue, 0, 9));

        if PrimaryInputMethod <> '' then
            MobXMLMgt.AddAttribute(XMLAddElement, 'primaryInputMethod', PrimaryInputMethod);
    end;

    procedure RC_List_TableData_CData(var XmlCDataSection: XmlCData; _DataTable: Text[50]; _DataKeyColumn: Text[50]; _DataDisplayColumn: Text[50]; _DefaultValue: Text[50]);
    begin

        // Standard table data values
        DataTable := _DataTable;                        // The name of the table in the reference data
        DataKeyColumn := _DataKeyColumn;                // The column to use for the data value
        DataDisplayColumn := _DataDisplayColumn;        // The column to vbuse for the value displayed in the list
        DefaultValue := _DefaultValue;                  // The initial value of the list. If "blank" is supplied the first entry is used.

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, LIST_Txt);
    end;

    procedure RC_List_TableData_XmlNode(var XMLSteps: XmlNode; _DataTable: Text[50]; _DataKeyColumn: Text[50]; _DataDisplayColumn: Text[50]; _DefaultValue: Text[50]);
    begin

        // Standard table data values
        DataTable := _DataTable;                        // The name of the table in the reference data
        DataKeyColumn := _DataKeyColumn;                // The column to use for the data value
        DataDisplayColumn := _DataDisplayColumn;        // The column to use for the value displayed in the list
        DefaultValue := _DefaultValue;                  // The initial value of the list. If "blank" is supplied the first entry is used.

        // Create the XML based on the set variables
        RC_Step_XmlNode(XMLSteps, LIST_Txt, false);
    end;

    procedure RC_List_TableData_Ext(_LinkedElement: Integer; _FilterColumn: Text[50]);
    begin
        // Set the extended variables

        // The ID of the step that is linked to this step (the step to get the value to filter on from)
        LinkedElement := _LinkedElement;

        // The column in the data table associated with this step where the data value from the linked step will be applied
        FilterColumn := _FilterColumn;

        // Example
        // Step 1 has a selected data value of "A"
        // Step 2 has a table that looks like this:
        // Data Column | Filter column
        //      1             A
        //      2             A
        //      3             B
        //      4             C

        // Result:
        // Only 1 and 2 is shown in the list
    end;

    procedure RC_List_ListData_CData(var XmlCDataSection: XmlCData; _ListValues: Text[1024]; _DefaultValue: Text[50]);
    begin
        // Standard list values
        ListValues := _ListValues;
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, LIST_Txt);
    end;

    procedure RC_List_ListData_XmlNode(var XMLSteps: XmlNode; _ListValues: Text[1024]; _DefaultValue: Text[50]);
    begin
        // Standard list values
        ListValues := _ListValues;
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XMLSteps, LIST_Txt, false);
    end;

    procedure RC_List_ListData_Ext(_ListSeparator: Text[1]);
    begin
        ListSeparator := _ListSeparator;
    end;

    procedure RC_Text_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _Length: Integer);
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, TEXT_Txt);
    end;

    procedure RC_Text_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[50]; _Length: Integer);
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, TEXT_Txt, false);
    end;

    procedure RC_TypeAndQty_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[50]; _Length: Integer);
    var
        MobXMLMgt: Codeunit "MOB XML Management";
        XMLAddElement: XmlNode;
        InputType: Text[50];
        ShowUnique: Boolean;
    begin

        InputType := 'Decimal';
        DefaultValue := _DefaultValue;
        Length := _Length;

        MobXMLMgt.AddElement(XMLSteps, 'typeAndQuantity', '', MobXMLMgt.GetNodeNSURI(XMLSteps), XMLAddElement);
        MobXMLMgt.AddAttribute(XMLAddElement, 'scanBehavior', 'Add');

        MobXMLMgt.AddAttribute(XMLAddElement, 'inputType', InputType);
        MobXMLMgt.AddAttribute(XMLAddElement, 'id', FORMAT(Id, 0, 9));
        MobXMLMgt.AddAttribute(XMLAddElement, 'name', Name);
        MobXMLMgt.AddAttribute(XMLAddElement, 'header', Header);
        MobXMLMgt.AddAttribute(XMLAddElement, 'label', Label);
        MobXMLMgt.AddAttribute(XMLAddElement, 'labelWidth', FORMAT(LabelWidth, 0, 9));
        MobXMLMgt.AddAttribute(XMLAddElement, 'helpLabel', HelpLabel);

        // For character based input fields the maximum allowed length can be set
        if Length <> -1 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'length', FORMAT(Length, 0, 9));

        // Determines if the mobile device automatically moves on to the next step if a value is scanned
        // If it is set to false the mobile device stays on the step until the user manually moves forward
        if AutoForwardAfterScan then
            MobXMLMgt.AddAttribute(XMLAddElement, 'autoForwardAfterScan', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'autoForwardAfterScan', 'false');

        // Determines if the step can be left blank / skipped or if the user must enter a value
        if Optional then
            MobXMLMgt.AddAttribute(XMLAddElement, 'optional', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'optional', 'false');

        // Determines if the step is shown to the user
        if Visible then
            MobXMLMgt.AddAttribute(XMLAddElement, 'visible', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'visible', 'false');

        // Use the default value to pre-populate the step with a value
        if DefaultValue <> '' then
            MobXMLMgt.AddAttribute(XMLAddElement, 'defaultValue', DefaultValue);

        // One or more GS1 application identifiers can be associated with a step
        MobXMLMgt.AddAttribute(XMLAddElement, 'eanAi', EanAi);

        // Perform Calculation
        if PerformCalculation then
            MobXMLMgt.AddAttribute(XMLAddElement, 'performCalculation', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'performCalculation', 'false');

        // Validation Values
        if ValidationValues <> '' then begin
            MobXMLMgt.AddAttribute(XMLAddElement, 'validationValues', ValidationValues);

            // Case sensitive
            if ValidationCaseSensitive then
                MobXMLMgt.AddAttribute(XMLAddElement, 'validationCaseSensitive', 'true')
            else
                MobXMLMgt.AddAttribute(XMLAddElement, 'validationCaseSensitive', 'false');
        end;

        // Overdelivery Validation
        MobXMLMgt.AddAttribute(XMLAddElement, 'overDeliveryValidation', OverDeliveryValidation);

        // Editable
        if Editable then
            MobXMLMgt.AddAttribute(XMLAddElement, 'editable', 'true')
        else
            MobXMLMgt.AddAttribute(XMLAddElement, 'editable', 'false');

        // Unique values
        /* if ShowUnique then
            if UniqueValues then
                MobXMLMgt.AddAttribute(XMLAddElement, 'uniqueValues', 'true')
            else
                MobXMLMgt.AddAttribute(XMLAddElement, 'uniqueValues', 'false'); */

        MobXMLMgt.AddAttribute(XMLAddElement, 'uniqueValues', 'true');

        // Resolution Height
        if ResolutionHeight <> -1 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'resolutionHeight', FORMAT(ResolutionHeight, 0, 9));

        // Min Value
        if MinValue <> -10000000 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'minValue', FORMAT(MinValue, 0, 9));

        // Max Value
        if MaxValue <> 10000000 then
            MobXMLMgt.AddAttribute(XMLAddElement, 'maxValue', FORMAT(MaxValue, 0, 9));

        if PrimaryInputMethod <> '' then
            MobXMLMgt.AddAttribute(XMLAddElement, 'primaryInputMethod', PrimaryInputMethod);
    end;



    procedure RC_Text_Ext(_HelpLabelMaximize: Boolean; _ValidationValues: Text[1024]; _ValidationCaseSensitive: Boolean; _ListSeparator: Text[1]);
    begin
        // Extended text values
        HelpLabelMaximize := _HelpLabelMaximize;
        ValidationValues := _ValidationValues;
        ValidationCaseSensitive := _ValidationCaseSensitive;
        ListSeparator := _ListSeparator;
    end;

    procedure RC_RadioButton_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _ListValues: Text[1024]; _ListSeparator: Text[1]);
    begin
        // Set the standard parameters
        DefaultValue := _DefaultValue;
        ListValues := _ListValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, RADIO_BUTTON_Txt);
    end;

    procedure RC_RadioButton_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[50]; _ListValues: Text[1024]; _ListSeparator: Text[1]);
    begin
        // Set the standard parameters
        DefaultValue := _DefaultValue;
        ListValues := _ListValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, RADIO_BUTTON_Txt, false);
    end;

    procedure RC_QtyByScan_CData(var XmlCDataSection: XmlCData; _Editable: Boolean; _MinValue: Decimal; _MaxValue: Decimal; _OverDeliveryValidation: Text[10]; _ListValues: Text[1024]; _ListSeparator: Text[1]; _DataTable: Text[50]; _DataKeyColumn: Text[50]);
    begin
        // Standard values
        Editable := _Editable;
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        OverDeliveryValidation := _OverDeliveryValidation;
        ListValues := _ListValues;
        ListSeparator := _ListSeparator;
        DataTable := _DataTable;
        DataKeyColumn := _DataKeyColumn;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, QUANTITY_BY_SCAN_Txt);
    end;

    procedure RC_QtyByScan_XmlNode(var XmlSteps: XmlNode; _Editable: Boolean; _MinValue: Decimal; _MaxValue: Decimal; _OverDeliveryValidation: Text[10]; _ListValues: Text[1024]; _ListSeparator: Text[1]; _DataTable: Text[50]; _DataKeyColumn: Text[50]);
    begin
        // Standard values
        Editable := _Editable;
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        OverDeliveryValidation := _OverDeliveryValidation;
        ListValues := _ListValues;
        ListSeparator := _ListSeparator;
        DataTable := _DataTable;
        DataKeyColumn := _DataKeyColumn;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, QUANTITY_BY_SCAN_Txt, false);
    end;

    procedure RC_MultiScan_CData(var XmlCDataSection: XmlCData; _UniqueValues: Boolean; _ListSeparator: Text[1]);
    begin
        // Standard values
        UniqueValues := _UniqueValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, MULTI_SCAN_Txt);
    end;

    procedure RC_MultiScan_XmlNode(var XmlSteps: XmlNode; _UniqueValues: Boolean; _ListSeparator: Text[1]);
    begin
        // Standard values
        UniqueValues := _UniqueValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, MULTI_SCAN_Txt, true);
    end;

    procedure RC_MultiLineText_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[1024]; _Length: Integer);
    begin
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, MULTI_LINE_TEXT_Txt);
    end;

    procedure RC_MultiLineText_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[1024]; _Length: Integer);
    begin
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, MULTI_LINE_TEXT_Txt, false);
    end;

    procedure RC_Information_CData(var XmlCDataSection: XmlCData);
    begin
        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, INFORMATION_Txt);
    end;

    procedure RC_Information_XmlNode(var XmlSteps: XmlNode);
    begin
        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, INFORMATION_Txt, false);
    end;

    procedure RC_ImageCapture_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _ListSeparator: Text[1]; _ResolutionHeight: Integer; _ResolutionWidth: Integer);
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        ListSeparator := _ListSeparator;
        ResolutionHeight := _ResolutionHeight;
        ResolutionWidth := _ResolutionWidth;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, IMAGECAPTURE_Txt);
    end;

    procedure RC_ImageCapture_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[50]; _ListSeparator: Text[1]; _ResolutionHeight: Integer; _ResolutionWidth: Integer);
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        ListSeparator := _ListSeparator;
        ResolutionHeight := _ResolutionHeight;
        ResolutionWidth := _ResolutionWidth;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, IMAGECAPTURE_Txt, false);
    end;

    procedure RC_Image_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[1024]);
    begin
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, IMAGE_Txt);
    end;

    procedure RC_Image_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[1024]);
    begin
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, IMAGE_Txt, false);
    end;

    procedure RC_SignatureCapture_CData(var XmlCDataSection: XmlCData);
    begin

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, SIGNATURE_Txt);
    end;

    procedure RC_SignatureCapture_XmlNode(var XmlSteps: XmlNode);
    begin

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, SIGNATURE_Txt, false);
    end;

    procedure RC_Decimal_CData(var XmlCDataSection: XmlCData; _DefaultValue: Decimal; _MinValue: Decimal; _MaxValue: Decimal; _Length: Integer; _PerformCalculation: Boolean);
    begin
        DefaultValue := FORMAT(_DefaultValue, 0, 9);
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        Length := _Length;
        PerformCalculation := _PerformCalculation;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, DECIMAL_Txt);
    end;

    procedure RC_Decimal_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Decimal; _MinValue: Decimal; _MaxValue: Decimal; _Length: Integer; _PerformCalculation: Boolean);
    begin
        DefaultValue := FORMAT(_DefaultValue, 0, 9);
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        Length := _Length;
        PerformCalculation := _PerformCalculation;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, DECIMAL_Txt, false);
    end;

    procedure RC_Date_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date);
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, DATE_Txt);
    end;

    procedure RC_Date_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date);
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, DATE_Txt, false);
    end;

    procedure RC_DateTime_CData(var XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date);
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, DATETIME_Txt);
    end;

    procedure RC_DateTime_XmlNode(var XmlSteps: XmlNode; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date);
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, DATETIME_Txt, false);
    end;

    procedure RC_Summary_CData(var XmlCDataSection: XmlCData; _LabelWidth: Integer);
    begin
        // Set the label width
        LabelWidth := _LabelWidth;

        // Create the XML based on the set variables
        RC_Step_CData(XmlCDataSection, SUMMARY_Txt);
    end;

    procedure RC_Summary_XmlNode(var XmlSteps: XmlNode; _LabelWidth: Integer);
    begin
        // Set the label width
        LabelWidth := _LabelWidth;

        // Create the XML based on the set variables
        RC_Step_XmlNode(XmlSteps, SUMMARY_Txt, false);
    end;

    procedure RC_Std_Parms(_Id: Integer; _Name: Text[50]; _Header: Text[100]; _Label: Text[100]; _HelpLabel: Text[100]);
    begin
        // Use this function to set the standard parameters for all step types
        // It initializes the advanced parameters to it's default values

        // Standard parameters for all steps
        Id := _Id;
        Name := _Name;
        Header := _Header;
        Label := _Label;
        HelpLabel := _HelpLabel;

        // Default values
        Length := -1;
        LabelWidth := 100;
        AutoForwardAfterScan := true;
        Optional := false;
        Visible := true;
        ListValues := '';
        ListSeparator := '';
        DataTable := '';
        DataKeyColumn := '';
        DataDisplayColumn := '';
        LinkedElement := -1;
        FilterColumn := '';
        DefaultValue := '';
        EanAi := '';
        PerformCalculation := false;
        HelpLabelMaximize := false;
        ValidationValues := '';
        ValidationCaseSensitive := false;
        Editable := true;
        MinValue := -10000000;
        MaxValue := 10000000;
        OverDeliveryValidation := WARN_Txt;
        UniqueValues := true;
        ResolutionHeight := -1;
        ResolutionWidth := -1;
        DateFormat := '';
        MinDate := 0D;
        MaxDate := 0D;
        PrimaryInputMethod := 'Scan';
    end;

    procedure RC_Ext_Parms(_EanAi: Text[50]; _AutoForwardAfterScan: Boolean; _Optional: Boolean; _Visible: Boolean; _LabelWidth: Integer);
    begin
        // Use this function to set the extended parameters for all step types
        LabelWidth := _LabelWidth;
        AutoForwardAfterScan := _AutoForwardAfterScan;
        Optional := _Optional;
        Visible := _Visible;
        EanAi := _EanAi;
    end;

    procedure RC_Ext_Parms_PrimaryInputMetho(_PrimaryInputMethod: Text[20]);
    begin
        PrimaryInputMethod := _PrimaryInputMethod;
    end;

    procedure "**** TEMPLATE CODE ******"();
    begin
    end;

    procedure ExampleCode(var XmlCDataSection: XmlCData; var XMLSteps: XmlNode);
    var
        _Id: Integer;
        _Name: Text[50];
        _Header: Text[100];
        _Label: Text[100];
        _HelpLabel: Text[100];
        _DataTable: Text[50];
        _DataKeyColumn: Text[50];
        _DataDisplayColumn: Text[50];
        _DefaultValue: Text[50];
        _DefaultDecimalValue: Decimal;
        _ListValues: Text[1024];
        _ListSeparator: Text[1];
        _EanAi: Text[50];
        _AutoForwardAfterScan: Boolean;
        _Optional: Boolean;
        _Visible: Boolean;
        _LabelWidth: Integer;
        _LinkedElement: Integer;
        _FilterColumn: Text[50];
        _HelpLabelMaximize: Boolean;
        _ValidationValues: Text[1024];
        _ValidationCaseSensitive: Boolean;
        _Length: Integer;
        _Editable: Boolean;
        _MinValue: Decimal;
        _MaxValue: Decimal;
        _OverDeliveryValidation: Text[10];
        _UniqueValues: Boolean;
        _ResolutionHeight: Integer;
        _ResolutionWidth: Integer;
        _PerformCalculation: Boolean;
        _DateFormat: Text[50];
        _MinDate: Date;
        _MaxDate: Date;
    begin

        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a simple list step with data from a table sent out as reference data
        //
        _Id := 1;
        _Name := 'SimpleListFromReferenceData';
        _Header := 'Select from the list...';
        _Label := 'Value';
        _HelpLabel := 'Text displayed directly under the list';
        _DataTable := 'TableA';           // Replace with a real table name from the reference data
        _DataKeyColumn := 'ColumnA';      // Replace with the column that holds the data value
        _DataDisplayColumn := 'ColumnB';  // Replace with the column that holds the values to display in the list
        _DefaultValue := '';              // Set this value to select something else that the first entry in the list

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the list
        RC_List_TableData_CData(XmlCDataSection, _DataTable, _DataKeyColumn, _DataDisplayColumn, _DefaultValue);
        RC_List_TableData_XmlNode(XMLSteps, _DataTable, _DataKeyColumn, _DataDisplayColumn, _DefaultValue);
        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



        // ****************************************************************************************
        // Add two list steps with data from a table sent out as reference data where the value in the first step
        // is used to filter the list used in the second step
        //

        // *** 1st step ***
        // Create the first step that will be used as a filter
        _Id := 10000;
        _Name := 'SimpleListFromReferenceData';
        _Header := 'Select from the list...';
        _Label := 'Value';
        _HelpLabel := 'Text displayed directly under the list';
        _DataTable := 'TableA';           // Replace with a real table name from the reference data
        _DataKeyColumn := 'ColumnA';      // Replace with the column that holds the data value
        _DataDisplayColumn := 'ColumnB';  // Replace with the column that holds the values to display in the list
        _DefaultValue := '';              // Set this value to select something else that the first entry in the list

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the list
        RC_List_TableData_CData(XmlCDataSection, _DataTable, _DataKeyColumn, _DataDisplayColumn, _DefaultValue);
        RC_List_TableData_XmlNode(XMLSteps, _DataTable, _DataKeyColumn, _DataDisplayColumn, _DefaultValue);

        // *** 2nd step ***
        // Create the second step
        _Id := 10001;
        _Name := 'SimpleListFromReferenceData';
        _Header := 'Select from the list...';
        _Label := 'Value';
        _HelpLabel := 'Text displayed directly under the list';
        _DataTable := 'TableB';           // Replace with a real table name from the reference data
        _DataKeyColumn := 'ColumnA';      // Replace with the column that holds the data value
        _DataDisplayColumn := 'ColumnB';  // Replace with the column that holds the values to display in the list
        _DefaultValue := '';              // Set this value to select something else that the first entry in the list

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // To set up the filter we need to set the extended parameters
        _LinkedElement := 10000;          // Here we supply the ID used for the step where the value to filter on comes from
        _FilterColumn := 'ColumnC';
        RC_List_TableData_Ext(_LinkedElement, _FilterColumn);

        // Create the list
        RC_List_TableData_CData(XmlCDataSection, _DataTable, _DataKeyColumn, _DataDisplayColumn, _DefaultValue);
        RC_List_TableData_XmlNode(XMLSteps, _DataTable, _DataKeyColumn, _DataDisplayColumn, _DefaultValue);
        //
        // ****************************************************************************************



        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a simple list step with data from string containing the values using a separator character
        _Id += 1;
        _Name := 'SimpleListFromList';
        _Header := 'Select from the list...';
        _Label := 'Value';
        _HelpLabel := 'Text displayed directly under the list';
        _ListValues := 'A;B;C;D';
        _DefaultValue := 'B';              // Set this value to select something else that the first entry in the list

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the list
        RC_List_ListData_CData(XmlCDataSection, _ListValues, _DefaultValue);
        RC_List_ListData_XmlNode(XMLSteps, _ListValues, _DefaultValue);
        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        // ****************************************************************************************
        // Add a list step with extended parameters with data from string containing the values using a separator character
        _Id += 1;
        _Name := 'SimpleListFromList';
        _Header := 'Select from the list...';
        _Label := 'Value';
        _HelpLabel := 'Text displayed directly under the list';
        _ListValues := 'A?B?C?D';
        _DefaultValue := 'B';               // Set this value to select something else that the first entry in the list
        _EanAi := '02';                     // Set the GS1 Application Identifier
        _AutoForwardAfterScan := false;     // This allows the user to see the scanned value before manually moving on to the next step
        _Optional := true;                  // This allows the user to skip entering a value in the step
        _Visible := false;                  // This hides the step, but it's value is still sent to NAV when posting.
                                            // Combined with a DefaultValue this can be a good way to transfer data needed for posting
                                            // without showing it to the user
        _LabelWidth := 150;                 // The standard width of the label in front of the input field is 100

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Set the extended parameters
        RC_Ext_Parms(_EanAi, _AutoForwardAfterScan, _Optional, _Visible, _LabelWidth);

        // Override the standard separator character
        _ListSeparator := '?';
        RC_List_ListData_Ext(_ListSeparator);

        // Create the list
        RC_List_ListData_CData(XmlCDataSection, _ListValues, _DefaultValue);
        RC_List_ListData_XmlNode(XMLSteps, _ListValues, _DefaultValue);
        //
        // ****************************************************************************************


        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a text step
        _Id += 1;
        _Name := 'TextStep';
        _Header := 'Enter a text value';
        _Label := 'Value';
        _HelpLabel := 'Text displayed directly under the field';   // This can be HTML if the "helpLabelMaximize" attribute is set to true
        _DefaultValue := 'A';               // Set this value to select something else that the first entry in the list
        _EanAi := '02';                     // Set the GS1 Application Identifier
        _AutoForwardAfterScan := false;     // This allows the user to see the scanned value before manually moving on to the next step
        _Optional := true;                  // This allows the user to skip entering a value in the step
        _Visible := true;                   // This hides the step, but it's value is still sent to NAV when posting.
                                            // Combined with a DefaultValue this can be a good way to transfer data needed for posting
                                            // without showing it to the user
        _LabelWidth := 100;                 // The standard width of the label in front of the input field is 100
        _Length := 20;                      // The mobile device will prevent the user from entering more than this number of characters

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Set the extended parameters
        RC_Ext_Parms(_EanAi, _AutoForwardAfterScan, _Optional, _Visible, _LabelWidth);

        // Set the extended text parameters
        _HelpLabelMaximize := true;         // This will expand the help label to use all the available space under the input field.
        _ValidationValues := 'A;B;C';       // The user can only enter one of these values
        _ValidationCaseSensitive := false;
        _ListSeparator := ';';
        RC_Text_Ext(_HelpLabelMaximize, _ValidationValues, _ValidationCaseSensitive, _ListSeparator);

        // Create the step
        RC_Text_CData(XmlCDataSection, _DefaultValue, _Length);
        RC_Text_XmlNode(XMLSteps, _DefaultValue, _Length);

        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



        // ****************************************************************************************
        // Add a Radio Button step
        _Id += 1;
        _Name := 'RadioButtonStep';
        _Header := 'Select a value';
        _Label := 'Value';
        _HelpLabel := '';                   // Not used on the radiobutton step
        _ListValues := 'A;B';               // The radio button can only handle two values. If more is needed then use a list
        _ListSeparator := ';';
        _DefaultValue := 'B';               // Set this value to select something else that the first entry in the list

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_RadioButton_CData(XmlCDataSection, _DefaultValue, _ListValues, _ListSeparator);
        RC_RadioButton_XmlNode(XMLSteps, _DefaultValue, _ListValues, _ListSeparator);
        // ****************************************************************************************


        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a QuantityByScan step
        _Id += 1;
        _Name := 'QuantityByScanStep';
        _Header := 'Scan to increment quantity';
        _Label := 'Quantity';
        _HelpLabel := 'Text displayed directly under the fields';

        _Editable := false;                                  // Controls if the user can enter the quantity manually
        _MinValue := 1;                                      // The minimum acceptable value
        _MaxValue := 5;                                      // The maximum acceptable value
        _OverDeliveryValidation := WARN_Txt;                     // Determines what happens if the user enters more than max (None/Warn/Block)
        _ListValues := 'ItenNumber;Barcode1;Barcode2';       // The user must scan a value found in this list to increment the quantity
        _ListSeparator := ';';
        _DataTable := '';                                    // Set this if you want to get the list values from a table
        _DataKeyColumn := '';                                // The column with the data

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_QtyByScan_CData(XmlCDataSection, _Editable, _MinValue, _MaxValue, _OverDeliveryValidation,
                          _ListValues, _ListSeparator, _DataTable, _DataKeyColumn);
        RC_QtyByScan_XmlNode(XMLSteps, _Editable, _MinValue, _MaxValue, _OverDeliveryValidation,
                          _ListValues, _ListSeparator, _DataTable, _DataKeyColumn);
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        // ****************************************************************************************
        // Add a MultiScan step
        _Id += 1;
        _Name := 'MultiScanStep';
        _Header := 'Scan all serial numbers';
        _Label := 'Quantity';
        _HelpLabel := '';                   // Not used on this step
        _ListSeparator := ';';
        _UniqueValues := true;              // Set this value to TRUE if it is not allowed to scan the same value multiple times

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_MultiScan_CData(XmlCDataSection, _UniqueValues, _ListSeparator);
        RC_MultiScan_XmlNode(XMLSteps, _UniqueValues, _ListSeparator);

        // ****************************************************************************************


        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a MultiLineText step
        _Id += 1;
        _Name := 'MultiLineTextStep';
        _Header := 'Multi Line Text';
        _Label := '';                       // Not used
        _HelpLabel := '';                   // Not used
        _DefaultValue := 'Here is a really long text to display on the mobile device in a MultiLineText step';
        _Length := 1000;

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_MultiLineText_CData(XmlCDataSection, _DefaultValue, _Length);
        RC_MultiLineText_XmlNode(XMLSteps, _DefaultValue, _Length);
        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        // ****************************************************************************************
        // Add an Information step
        _Id += 1;
        _Name := 'InformationStep';
        _Header := 'Information';
        _Label := 'Text in bold';
        _HelpLabel := 'The longer message to the user';

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_Information_CData(XmlCDataSection);
        RC_Information_XmlNode(XMLSteps);

        // How to inject attribute values when adding the collector
        // 'CollectorKey{[key][attribute][value]}'
        // Example
        // MobXMLMgt.AddElement(XMLOrderLine,'RegisterExtraInfo','DemoOrderLineExtraInfo{[Demo][helpLabel][This a help text]}',NS_BASE_DATA_MODEL,XMLCreatedNode);

        //
        // ****************************************************************************************


        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add an ImageCapture step
        _Id += 1;
        _Name := 'ImageCaptureStep';
        _Header := 'Take a picture';
        _Label := '';
        _HelpLabel := '';
        _DefaultValue := '\Tasklet Factory\Pictures\';       // The folder on the mobile device where the pictures are stored
        _ListSeparator := ';';
        _ResolutionHeight := 800;                            // The resolution must match a valid resolution on the mobile device
        _ResolutionWidth := 600;                             // Start the camera on the mobile device to see the valid resolutions

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_ImageCapture_CData(XmlCDataSection, _DefaultValue, _ListSeparator, _ResolutionHeight, _ResolutionWidth);
        RC_ImageCapture_XmlNode(XMLSteps, _DefaultValue, _ListSeparator, _ResolutionHeight, _ResolutionWidth);

        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        // ****************************************************************************************
        // Add an Image step
        // Supported file types: GIF,JPG,PNG
        _Id += 1;
        _Name := 'ImageStep';
        _Header := 'Show a picture';
        _Label := '';
        _HelpLabel := '';
        _DefaultValue := '\Tasklet Factory\Pictures\';
        // The URL to the picture. It can either be the path to a picture on the mobile
        // device or a link to a picture on the network
        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_Image_CData(XmlCDataSection, _DefaultValue);
        RC_Image_XmlNode(XMLSteps, _DefaultValue);

        //
        // ****************************************************************************************

        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a Decimal step
        _Id += 1;
        _Name := 'DecimalStep';
        _Header := 'Enter a number';
        _Label := 'Qty:';
        _HelpLabel := 'UoM = PCS';
        _DefaultDecimalValue := 0;
        _MinValue := 0;
        _MaxValue := 100;
        _Length := 3;
        _PerformCalculation := true;

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_Decimal_CData(XmlCDataSection, _DefaultDecimalValue, _MinValue, _MaxValue, _Length, _PerformCalculation);
        RC_Decimal_XmlNode(XMLSteps, _DefaultDecimalValue, _MinValue, _MaxValue, _Length, _PerformCalculation);

        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        // ****************************************************************************************
        // Add a Date step
        _Id += 1;
        _Name := 'DateStep';
        _Header := 'Set the date';
        _Label := 'Exp. date:';
        _HelpLabel := '';
        _DefaultValue := '24-12-2014';
        _DateFormat := 'dd-MM-yyyy';
        _MinDate := 0D;
        _MaxDate := 0D;

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_Date_CData(XmlCDataSection, _DefaultValue, _DateFormat, _MinDate, _MaxDate);
        RC_Date_XmlNode(XMLSteps, _DefaultValue, _DateFormat, _MinDate, _MaxDate);

        //
        // ****************************************************************************************

        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a DateTime step
        _Id += 1;
        _Name := 'DateTimeStep';
        _Header := 'Set the date and time';
        _Label := 'Start:';
        _HelpLabel := 'Set the start time';
        _DefaultValue := '';
        _DateFormat := 'dd-MM-yyyy';
        _MinDate := 0D;
        _MaxDate := 0D;

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_DateTime_CData(XmlCDataSection, _DefaultValue, _DateFormat, _MinDate, _MaxDate);
        RC_DateTime_XmlNode(XMLSteps, _DefaultValue, _DateFormat, _MinDate, _MaxDate);

        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


        // ****************************************************************************************
        // Add a summary step
        _Id += 1;
        _Name := 'SummaryStep';
        _Header := 'Summary';
        _LabelWidth := 100;                 // Sets the width of the label column
        _Label := '';                       // Not used
        _HelpLabel := '';                   // Not used

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_Summary_CData(XmlCDataSection, _LabelWidth);
        RC_Summary_XmlNode(XMLSteps, _LabelWidth);
        // ****************************************************************************************

        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // Add a Signature step
        _Id += 1;
        _Name := 'SignatureStep';
        _Header := 'Signature';
        _Label := 'Sign:';
        _HelpLabel := 'Tap the signature icon to provide signature';

        // Set the basic required values
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);

        // Create the step
        RC_SignatureCapture_CData(XmlCDataSection);
        RC_SignatureCapture_XmlNode(XMLSteps);

        //
        // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    end;
}

