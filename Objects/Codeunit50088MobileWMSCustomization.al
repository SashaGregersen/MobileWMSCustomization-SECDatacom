codeunit 50088 "Mobile WMS customization"
{
    SingleInstance = true;
    EventSubscriberInstance = StaticAutomatic;


    [EventSubscriber(ObjectType::codeunit, codeunit::"MOB WMS Reference Data", 'OnAfterAddHeaderConfiguration', '', true, true)]
    local procedure HeaderConfigurationOnAfterAddEvent(var _XMLResponseData: XmlNode)
    var
        MobWMSRef: codeunit "MOB WMS Reference Data";
    begin
        MobWMSRef.CreateHeaderConfiguration(_XMLResponseData, 'SerialNumberReceiveHeader');
    end;

    [EventSubscriber(ObjectType::Codeunit, codeunit::"MOB WMS Reference Data", 'OnAddCustomHeaderValues', '', true, true)]
    local procedure AddCustomerHeaderValues(var _XmlCDataSection: XmlCData; _Key: Text[50]; var _IsHandled: Boolean)
    var
        MobWMSRef: codeunit "MOB WMS Reference Data";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobBaseToolbox: Codeunit "MOB Toolbox";
    begin
        case _Key of
            'SerialNumberReceiveHeader':
                begin
                    MobWMSRef.AddConfHeaderTextValue(_XmlCDataSection,
                               1,                 //id
                               'OrderBackendID',      //name
                               'Order No.:',  //label
                               100,               //label width
                               false,              //clear on clear
                               false,              //accept barcode
                               20,                //length
                               false,             //optional
                               '',      //search type
                               '',  //ean GS1Ai
                               true);            //locked
                                                 // Item
                    MobWMSRef.AddConfHeaderTextValue(_XmlCDataSection,
                                           2,                 //id
                                           'ItemNumber',      //name
                                           MobWmsLanguage.GetMessage('ITEM') + ':',  //label
                                           100,               //label width
                                           true,              //clear on clear
                                           true,              //accept barcode
                                           20,                //length
                                           false,             //optional
                                           'ItemSearch',      //search type
                                           MobBaseToolbox.GetItemNoGS1Ai(),  //ean GS1Ai
                                           FALSE);            //locked

                    _IsHandled := true;

                end;

        end;

    end;

    [EventSubscriber(ObjectType::codeunit, codeunit::"MOB WMS Adhoc Registr.", 'OnCreateCustomRegCollectorConfig', '', true, true)]
    local procedure OnCreateCustomRegCollectorConfigEvent(var _XMLRequestDoc: XmlDocument; var _XMLSteps: XmlNode; _RegistrationType: Text; var _RegistrationTypeTracking: Text[200]; var _IsHandled: Boolean)
    var
        ItemVariant: Record "Item Variant";
        XMLRequestNode: XmlNode;
        XMLRequestDataNode: XmlNode;
        XMLParameterNode: XmlNode;
        ItemNo: Code[20];
        MobXMLMgt: Codeunit "MOB XML Management";
        MobWMSToolbox: Codeunit "MOB WMS Toolbox";
        MobBaseToolbox: codeunit "MOB Toolbox";
        MobConfTools: Codeunit "MOB WMS Conf. Tools";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        SECMobConfTools: codeunit "SEC MOB WMS Conf. Tools";
        Item: record item;
    begin
        CASE _RegistrationType of
            'SerialNumberReceive':
                begin
                    MobXMLMgt.GetDocRootNode(_XMLRequestDoc, XMLRequestNode);
                    MobXMLMgt.FindNode(XMLRequestNode, MobWMSToolbox."CONST::requestData"(), XMLRequestDataNode);

                    // -- Now find the item parameter
                    MobXMLMgt.FindNode(XMLRequestDataNode, 'ItemNumber', XMLParameterNode);
                    // -- Get the parameter
                    ItemNo := MobWMSToolbox.GetItemNumber(MobBaseToolbox.ReadMisc(MobXmlMgt.GetNodeInnerText(XMLParameterNode)));

                    // Set the tracking value displayed in the document queue
                    _RegistrationTypeTracking := StrSubstNo('SerialNumberReceive' + ': %1', ItemNo);

                    // To Bin
                    // Set the basic required values
                    MobConfTools.RC_Std_Parms(1,
                                              'Bin',
                                              MobWmsLanguage.GetMessage('ITEM') + ' ' + ItemNo + ' - ' +
                                              MobWmsLanguage.GetMessage('ENTER_TO_BIN'),
                                              MobWmsLanguage.GetMessage('TO_BIN_LABEL') + ':',
                                              MobWmsLanguage.GetMessage('DEFAULT') + ': ' /* + GetDefaultBin(ItemNo, LocationCode, VariantCode) */);

                    // Set the extended parameters
                    MobConfTools.RC_Ext_Parms(MobBaseToolbox.GetBinGS1Ai(),
                                              true,
                                              false,
                                              true,
                                              100);

                    // Create the step
                    MobConfTools.RC_Text_XmlNode(_XMLSteps,
                                                 '',
                                                 20);

                    SECMobConfTools.RC_Std_Parms(1, 'SerialNumbers',
                                    'Scan Serial Numbers',
                                    '', '');

                    // Set the extended parameters
                    SECMobConfTools.RC_Ext_Parms('21',
                                              false,
                                              false,
                                              true,
                                              100);

                    // Create the step
                    SECMobConfTools.RC_TypeAndQty_XmlNode(_XMLSteps, '', 20);

                    _IsHandled := true;
                end;
        END;
    end;

    [EventSubscriber(ObjectType::codeunit, codeunit::"MOB WMS Adhoc Registr.", 'OnPostCustomAdhocRegistration', '', true, true)]
    local procedure OnPostCustomAdhocRegistrationEvent(var _XMLRequestDoc: XmlDocument; _RegistrationType: Text; var _RegistrationTypeTracking: Text[200]; var _IsHandled: Boolean)
    var
        XMLRequestNode: XmlNode;
        XMLRequestDataNode: XmlNode;
        XMLParameterNode: XmlNode;
        ItemNo: Code[20];
        MobXMLMgt: Codeunit "MOB XML Management";
        MobWMSToolbox: Codeunit "MOB WMS Toolbox";
        MobBaseToolbox: codeunit "MOB Toolbox";
        Item: record item;
    begin
        CASE _RegistrationType of
            'SerialNumberReceive':
                begin
                    MobXMLMgt.GetDocRootNode(_XMLRequestDoc, XMLRequestNode);
                    MobXMLMgt.FindNode(XMLRequestNode, MobWMSToolbox."CONST::requestData"(), XMLRequestDataNode);

                    // -- Now find the item parameter
                    MobXMLMgt.FindNode(XMLRequestDataNode, 'ItemNumber', XMLParameterNode);
                    // -- Get the parameter
                    ItemNo := MobWMSToolbox.GetItemNumber(MobBaseToolbox.ReadMisc(MobXmlMgt.GetNodeInnerText(XMLParameterNode)));

                    // Set the tracking value displayed in the document queue
                    _RegistrationTypeTracking := StrSubstNo('SerialNumberReceive' + ': %1', ItemNo);

                    item.get(ItemNo);
                    if item."Item Tracking Code" = '' then
                        Error('The item does not have item tracking');

                    PostPutAwayWithSerialNo(_XMLRequestDoc, ItemNo);
                    Message('Posting Complete');

                    _IsHandled := true;
                end;
        END;
    end;

    procedure PostPutAwayWithSerialNo(var XmlRequestDoc: XmlDocument; ItemNo: code[20])
    var
        MobXMLMgt: Codeunit "MOB XML Management";
        XMLRequestNode: XmlNode;
        XMLRequestDataNode: XmlNode;
        XMLParameterNode: XmlNode;
        WhseActivityLine: record "Warehouse Activity Line";
        SerialNumbersTxt: text[1024];
        i: integer;
        SerialNumbers: integer;
        WhseDocNo: code[20];
        BinCode: code[20];
        SerialNo: code[50];
        MobReg: Record "MOB WMS Registration";
        MobWMSToolbox: codeunit "MOB WMS Toolbox";
        MobBaseToolbox: codeunit "MOB Toolbox";
        MobWmsLanguage: codeunit "MOB WMS Language";
        Post: Boolean;
        TempWhseActivityLine: record "Warehouse Activity Line" temporary;
        WhsePostLine: codeunit "Post Put Away Serial";
        MobDocQueue: record "MOB Document Queue";
        xmlresultdoc: XmlDocument;
        WhseActivityLine2: record "Warehouse Activity Line";

    begin
        MobXMLMgt.GetDocRootNode(XMLRequestDoc, XMLRequestNode);
        MobXMLMgt.FindNode(XMLRequestNode, MobWMSToolbox."CONST::requestData"(), XMLRequestDataNode);
        MobXMLMgt.FindNode(XMLRequestDataNode, 'SerialNumbers', XMLParameterNode);
        SerialNumbersTxt := MobXmlMgt.GetNodeInnerText(XMLParameterNode);
        SerialNumbers := STRLEN(DELCHR(SerialNumbersTxt, '=', DELCHR(SerialNumbersTxt, '=', '=')));
        MobXMLMgt.FindNode(XMLRequestDataNode, 'OrderBackendID', XMLParameterNode);
        WhseDocNo := MobXmlMgt.GetNodeInnerText(XMLParameterNode);
        MobXMLMgt.FindNode(XMLRequestDataNode, 'Bin', XMLParameterNode);
        BinCode := MobBaseToolbox.ReadMisc(MobXmlMgt.GetNodeInnerText(XMLParameterNode));

        For i := 1 to SerialNumbers do begin
            WhseActivityLine.setrange("Action Type", WhseActivityLine."Activity Type"::"Invt. Put-away");
            WhseActivityLine.setrange("No.", WhseDocNo);
            WhseActivityLine.setrange("Item No.", ItemNo);
            WhseActivityLine.setrange("Serial No.", '');
            WhseActivityLine.SetRange("Qty. Outstanding (Base)", 1);
            WhseActivityLine.setrange("Action Type", WhseActivityLine."Action Type"::Place);
            if WhseActivityLine.FindFirst() then begin
                CheckAndGetSerialNo(SerialNumbersTxt, SerialNo);
                CheckIfSerialIsUsedBefore(WhseActivityLine, SerialNo);
                WhseActivityLine.validate("Serial No.", SerialNo);
                WhseActivityLine.validate("Bin Code", BinCode);
                WhseActivityLine.validate("Qty. to Handle", 1);
                WhseActivityLine.Modify(true);
                TempWhseActivityLine.Init();
                TempWhseActivityLine := WhseActivityLine;
                TempWhseActivityLine.Insert(true);
                Post := true;
            end;
        end;

        if Post then begin
            if TempWhseActivityLine.FindFirst() then begin
                if WhseActivityLine2.get(TempWhseActivityLine."Activity Type", TempWhseActivityLine."No.", TempWhseActivityLine."Line No.") then begin
                    TempWhseActivityLine.DeleteAll();
                    WhsePostLine.Run(WhseActivityLine2);
                end;
            end;
        end;

    end;

    procedure CheckAndGetSerialNo(var SerialNumbersTxt: text[1024]; var serialNo: code[50])
    var
        txt: text[1024];
        Pos: integer;
    begin
        serialNo := CopyStr(SerialNumbersTxt, 1, (StrPos(SerialNumbersTxt, '=') - 1));
        //Test qty scanned
        pos := StrPos(SerialNumbersTxt, ';');
        if pos > 0 then begin
            txt := CopyStr(SerialNumbersTxt, (StrPos(SerialNumbersTxt, '=') + 1), StrPos(SerialNumbersTxt, ';'));
            txt := CopyStr(txt, 1, (StrPos(txt, ';') - 1));
            if txt <> '1' then
                Error('You have scanned serial no %1 more than one time', SerialNumber);
        end else begin
            txt := CopyStr(SerialNumbersTxt, (StrPos(SerialNumbersTxt, '=') + 1));
            if txt <> '1' then
                Error('You have scanned serial no %1 more than one time', SerialNumber);
        end;
        //remove serialno from serialnumberstxt
        SerialNumbersTxt := CopyStr(SerialNumbersTxt, StrLen(serialNo) + 4);
    end;

    local procedure CheckIfSerialIsUsedBefore(WhseActLine: record "Warehouse Activity Line"; serialNo: code[50])
    var
        WMSMgt: codeunit "WMS Management";
    begin
        if WMSMgt.SerialNoOnInventory(WhseActLine."Location Code", WhseActLine."Item No.", WhseActLine."Variant Code", serialNo) then
            Error('Serial no. %1 is already on inventory on item %2', serialNo, WhseActLine."Item No.");
    end;

    /* [EventSubscriber(ObjectType::codeunit, codeunit::"Purch.-Post", 'OnAfterCheckTrackingAndWarehouseForReceive', '', true, true)]
    local procedure OnAfterCheckTrackingAndWarehouseForReceiveEvent(var PurchaseHeader: Record "Purchase Header"; var Receive: Boolean; CommitIsSupressed: Boolean)
    var
        whseactivityline: record "Warehouse Activity Line";
        Purchheader: record "Purchase Header";
    begin
        if not Receive then begin
            whseactivityline.setrange("Source No.", PurchaseHeader."No.");
            whseactivityline.SetRange("Activity Type", whseactivityline."Activity Type"::"Invt. Put-away");
            whseactivityline.SetRange("Action Type", whseactivityline."Action Type"::Place);
            if whseactivityline.FindSet() then
                if Purchheader.get(PurchaseHeader."Document Type", PurchaseHeader."No.") then
                    if Purchheader.Receive = true then
                        Receive := true;
        end; 
    end; */

    [EventSubscriber(ObjectType::codeunit, codeunit::"Whse.-Activity-Post", 'OnCodeOnAfterCreatePostedWhseActivDocument', '', true, true)]
    local procedure OnCodeOnAfterCreatePostedWhseActivDocumentEvent(VAR WhseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseActPost: codeunit "Whse.-Activity-Post";
    begin
        WhseActPost.PrintDocument(true);
    end;
}