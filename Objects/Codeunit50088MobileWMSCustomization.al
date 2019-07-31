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
}