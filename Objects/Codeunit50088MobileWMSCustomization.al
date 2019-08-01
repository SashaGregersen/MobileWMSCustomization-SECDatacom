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

                    // From Bin
                    // Set the basic required values
                    MobConfTools.RC_Std_Parms(1,
                                              'Bin',
                                              MobWmsLanguage.GetMessage('ITEM') + ' ' + ItemNo + ' - ' +
                                              MobWmsLanguage.GetMessage('ENTER_FROM_BIN'),
                                              MobWmsLanguage.GetMessage('FROM_BIN_LABEL') + ':',
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
                end;
        END;
    end;
}