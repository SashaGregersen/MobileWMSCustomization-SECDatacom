codeunit 50087 "Post Put Away Serial"
{
    // resembles codeunit 7324 
    // only difference is where SEC is added
    TableNo = "Warehouse Activity Line";
    trigger OnRun()
    begin
        WhseActivLine.COPY(Rec);
        Code;
        Rec := WhseActivLine;
    end;

    LOCAL procedure Code()
    var
        WhseProdRelease: Codeunit "Whse.-Production Release";
        WhseOutputRelease: Codeunit "Whse.-Output Prod. Release";
        TransferOrderPostPrint: Codeunit "TransferOrder-Post + Print";
        ItemTrackingRequired: Boolean;
        Selection: Option " ","Shipment","Receipt";
        ForceDelete: Boolean;
    begin
        PostingReference := WhseSetup.GetNextReference;

        WITH WhseActivHeader DO BEGIN
            WhseActivLine.SETRANGE("Activity Type", WhseActivLine."Activity Type");
            WhseActivLine.SETRANGE("No.", WhseActivLine."No.");
            WhseActivLine.SETFILTER("Qty. to Handle", '<>0');
            //SEC - commented out in order to receive partial put away
            //>>>
            /*IF NOT WhseActivLine.FIND('-') THEN
                ERROR(Text003); */
            //<<<

            GET(WhseActivLine."Activity Type", WhseActivLine."No.");
            GetLocation("Location Code");

            IF Type = Type::"Invt. Put-away" THEN
                WhseRequest.GET(
                  WhseRequest.Type::Inbound, "Location Code",
                  "Source Type", "Source Subtype", "Source No.")
            ELSE
                WhseRequest.GET(
                  WhseRequest.Type::Outbound, "Location Code",
                  "Source Type", "Source Subtype", "Source No.");
            IF WhseRequest."Document Status" <> WhseRequest."Document Status"::Released THEN
                ERROR('The source document %1 %2 is not released.', "Source Document", "Source No.");

            IF NOT HideDialog THEN BEGIN
                Window.OPEN(
                  'Warehouse Activity    #1##########\\' +
                  'Checking lines        #2######\' +
                  'Posting lines         #3###### @4@@@@@@@@@@@@@');
                Window.UPDATE(1, "No.");
            END;

            // Check Lines
            OnBeforeCheckLines(WhseActivHeader);

            LineCount := 0;

            IF WhseActivLine.FIND('-') THEN begin
                TempWhseActivLine.SETCURRENTKEY("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                REPEAT
                    LineCount := LineCount + 1;
                    IF NOT HideDialog THEN
                        Window.UPDATE(2, LineCount);
                    WhseActivLine.TESTFIELD("Item No.");
                    IF Location."Bin Mandatory" THEN BEGIN
                        WhseActivLine.TESTFIELD("Unit of Measure Code");
                        WhseActivLine.TESTFIELD("Bin Code");
                    END;
                    ItemTrackingRequired := CheckItemTracking(WhseActivLine);
                    InsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);
                UNTIL WhseActivLine.NEXT = 0;
            end;

            NoOfRecords := LineCount;

            // Posting lines
            SourceCodeSetup.GET;
            LineCount := 0;
            WhseActivLine.LOCKTABLE;

            IF WhseActivLine.FIND('-') THEN begin
                IF Type = Type::"Invt. Put-away" THEN BEGIN
                    PostedInvtPutAwayHdr.LOCKTABLE;
                    PostedInvtPutAwayLine.LOCKTABLE;
                END ELSE BEGIN
                    PostedInvtPickHdr.LOCKTABLE;
                    PostedInvtPickLine.LOCKTABLE;
                END;

                IF "Source Document" = "Source Document"::"Prod. Consumption" THEN BEGIN
                    PostConsumption;
                    WhseProdRelease.Release(ProdOrder);
                END ELSE
                    IF (Type = Type::"Invt. Put-away") AND
                       ("Source Document" = "Source Document"::"Prod. Output")
                    THEN BEGIN
                        PostOutput;
                        WhseOutputRelease.Release(ProdOrder);
                    END ELSE
                        PostSourceDoc;

                CreatePostedActivHeader(WhseActivHeader);

                REPEAT
                    LineCount := LineCount + 1;
                    IF NOT HideDialog THEN BEGIN
                        Window.UPDATE(3, LineCount);
                        Window.UPDATE(4, ROUND(LineCount / NoOfRecords * 10000, 1));
                    END;

                    IF Location."Bin Mandatory" THEN
                        PostWhseJnlLine(WhseActivLine);
                    CreatePostedActivLine(WhseActivLine);

                UNTIL WhseActivLine.NEXT = 0;
                OnCodeOnAfterCreatePostedWhseActivDocument(WhseActivHeader);
            END;

            // SEC - To support partial put away
            // Modify/delete activity header and activity lines
            //TempWhseActivLine.DELETEALL;

            WhseActivLine.SETCURRENTKEY(
              "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");

            IF WhseActivLine.FIND('-') THEN
                REPEAT
                    ForceDelete := FALSE;
                    OnBeforeWhseActivLineDelete(WhseActivLine, ForceDelete);
                    IF (WhseActivLine."Qty. Outstanding" = WhseActivLine."Qty. to Handle") OR ForceDelete THEN
                        //WhseActivLine.DELETE
                        WhseActivLine.DELETE(false)
                    ELSE BEGIN
                        WhseActivLine.VALIDATE(
                          "Qty. Outstanding", WhseActivLine."Qty. Outstanding" - WhseActivLine."Qty. to Handle");
                        IF HideDialog THEN
                            WhseActivLine.VALIDATE("Qty. to Handle", 0);
                        WhseActivLine.VALIDATE(
                          "Qty. Handled", WhseActivLine.Quantity - WhseActivLine."Qty. Outstanding");
                        WhseActivLine.MODIFY;
                        OnAfterWhseActivLineModify(WhseActivLine);
                    END;
                UNTIL WhseActivLine.NEXT = 0
            else
                WhseActivHeader.Delete(true);


            WhseActivLine.RESET;
            WhseActivLine.SETRANGE("Activity Type", Type);
            WhseActivLine.SETRANGE("No.", "No.");
            // SEC - to support partial  put away
            //>>>
            //WhseActivLine.SETFILTER("Qty. Outstanding", '<>%1', 0);
            //WhseActivLine.setrange("Qty. Outstanding", 0);
            //WhseActivLine.setrange("Qty. Handled", 1);

            IF not WhseActivLine.FIND('-') THEN
                //WhseActicLine.Delete(TRUE);
                WhseActivHeader.delete(true);
            //<<<
            IF NOT HideDialog THEN
                Window.CLOSE;

            IF PrintDoc THEN
                CASE "Source Document" OF
                    "Source Document"::"Purchase Order",
                  "Source Document"::"Purchase Return Order":
                        PurchPostPrint.GetReport(PurchHeader);
                    "Source Document"::"Sales Order",
                  "Source Document"::"Sales Return Order":
                        SalesPostPrint.GetReport(SalesHeader);
                    "Source Document"::"Inbound Transfer":
                        TransferOrderPostPrint.PrintReport(TransHeader, Selection::Receipt);
                    "Source Document"::"Outbound Transfer":
                        TransferOrderPostPrint.PrintReport(TransHeader, Selection::Shipment);
                END;

            COMMIT;
            CLEAR(WhseJnlRegisterLine);
        END;
    end;

    LOCAL procedure InsertTempWhseActivLine(WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
        OnBeforeInsertTempWhseActivLine(WhseActivLine, ItemTrackingRequired);

        WITH WhseActivLine DO BEGIN
            //SEC - to support partial put away
            //>>>
            /* TempWhseActivLine.SetSourceFilter(
              WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.",
              WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", FALSE); */
            //<<<
            IF TempWhseActivLine.get(WhseActivLine."Activity Type", WhseActivLine."No.", WhseActivLine."Line No.") THEN BEGIN
                //SEC - to support partial put away
                //>>>
                //TempWhseActivLine."Qty. to Handle" += "Qty. to Handle";
                //TempWhseActivLine."Qty. to Handle (Base)" += "Qty. to Handle (Base)";
                //<<<
                TempWhseActivLine."Qty. to Handle" := "Qty. to Handle";
                TempWhseActivLine."Qty. to Handle (Base)" := "Qty. to Handle (Base)";
                TempWhseActivLine.MODIFY;
                //>>>
                IF ItemTrackingRequired AND
                   ("Activity Type" IN ["Activity Type"::"Invt. Pick", "Activity Type"::"Invt. Put-away"])
                THEN
                    ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WhseActivLine);
                //<<<
            END ELSE BEGIN
                TempWhseActivLine.INIT;
                TempWhseActivLine := WhseActivLine;
                TempWhseActivLine.INSERT;
                IF ItemTrackingRequired AND
                   ("Activity Type" IN ["Activity Type"::"Invt. Pick", "Activity Type"::"Invt. Put-away"])
                THEN
                    ItemTrackingMgt.SynchronizeWhseActivItemTrkg(WhseActivLine);
            END;
        END;
    end;

    LOCAL procedure InitSourceDocument()
    var
        SalesLine: Record "Sales Line";
        SalesRelease: Codeunit "Release Sales Document";
        PurchRelease: Codeunit "Release Purchase Document";
        ModifyHeader: Boolean;
    begin
        OnBeforeInitSourceDocument(WhseActivHeader);

        WITH WhseActivHeader DO
            CASE "Source Type" OF
                DATABASE::"Purchase Line":
                    BEGIN
                        PurchHeader.GET("Source Subtype", "Source No.");
                        PurchLine.SETRANGE("Document Type", "Source Subtype");
                        PurchLine.SETRANGE("Document No.", "Source No.");
                        IF PurchLine.FIND('-') THEN
                            REPEAT
                                IF "Source Document" = "Source Document"::"Purchase Order" THEN
                                    PurchLine.VALIDATE("Qty. to Receive", 0)
                                ELSE
                                    PurchLine.VALIDATE("Return Qty. to Ship", 0);
                                PurchLine.VALIDATE("Qty. to Invoice", 0);
                                PurchLine.MODIFY;
                                OnAfterPurchLineModify(PurchLine);
                            UNTIL PurchLine.NEXT = 0;

                        IF (PurchHeader."Posting Date" <> "Posting Date") AND ("Posting Date" <> 0D) THEN BEGIN
                            PurchRelease.Reopen(PurchHeader);
                            PurchHeader.SetHideValidationDialog(TRUE);
                            PurchHeader.VALIDATE("Posting Date", "Posting Date");
                            PurchRelease.RUN(PurchHeader);
                            ModifyHeader := TRUE;
                        END;
                        IF "External Document No." <> '' THEN BEGIN
                            PurchHeader."Vendor Shipment No." := "External Document No.";
                            ModifyHeader := TRUE;
                        END;
                        IF "External Document No.2" <> '' THEN BEGIN
                            IF "Source Document" = "Source Document"::"Purchase Order" THEN
                                PurchHeader."Vendor Invoice No." := "External Document No.2"
                            ELSE
                                PurchHeader."Vendor Cr. Memo No." := "External Document No.2";
                            ModifyHeader := TRUE;
                        END;
                        IF ModifyHeader THEN
                            PurchHeader.MODIFY;
                    END;
                DATABASE::"Sales Line":
                    BEGIN
                        SalesHeader.GET("Source Subtype", "Source No.");
                        SalesLine.SETRANGE("Document Type", "Source Subtype");
                        SalesLine.SETRANGE("Document No.", "Source No.");
                        IF SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete THEN
                            SalesLine.SETRANGE(Type, SalesLine.Type::Item);
                        IF SalesLine.FIND('-') THEN
                            REPEAT
                                IF "Source Document" = "Source Document"::"Sales Order" THEN
                                    SalesLine.VALIDATE("Qty. to Ship", 0)
                                ELSE
                                    SalesLine.VALIDATE("Return Qty. to Receive", 0);
                                SalesLine.VALIDATE("Qty. to Invoice", 0);
                                SalesLine.MODIFY;
                                OnAfterSalesLineModify(SalesLine);
                            UNTIL SalesLine.NEXT = 0;

                        IF (SalesHeader."Posting Date" <> "Posting Date") AND ("Posting Date" <> 0D) THEN BEGIN
                            SalesRelease.Reopen(SalesHeader);
                            SalesHeader.SetHideValidationDialog(TRUE);
                            SalesHeader.VALIDATE("Posting Date", "Posting Date");
                            SalesRelease.RUN(SalesHeader);
                            ModifyHeader := TRUE;
                        END;
                        IF "External Document No." <> '' THEN BEGIN
                            SalesHeader."External Document No." := "External Document No.";
                            ModifyHeader := TRUE;
                        END;
                        IF ModifyHeader THEN
                            SalesHeader.MODIFY;
                    END;
                DATABASE::"Transfer Line":
                    BEGIN
                        TransHeader.GET("Source No.");
                        TransLine.SETRANGE("Document No.", TransHeader."No.");
                        TransLine.SETRANGE("Derived From Line No.", 0);
                        TransLine.SETFILTER("Item No.", '<>%1', '');
                        IF TransLine.FIND('-') THEN
                            REPEAT
                                TransLine.VALIDATE("Qty. to Ship", 0);
                                TransLine.VALIDATE("Qty. to Receive", 0);
                                TransLine.MODIFY;
                                OnAfterTransLineModify(TransLine);
                            UNTIL TransLine.NEXT = 0;

                        IF (TransHeader."Posting Date" <> "Posting Date") AND ("Posting Date" <> 0D) THEN BEGIN
                            TransHeader.CalledFromWarehouse(TRUE);
                            TransHeader.VALIDATE("Posting Date", "Posting Date");
                            ModifyHeader := TRUE;
                        END;
                        IF "External Document No." <> '' THEN BEGIN
                            TransHeader."External Document No." := "External Document No.";
                            ModifyHeader := TRUE;
                        END;
                        IF ModifyHeader THEN
                            TransHeader.MODIFY;
                    END;
            END;

        OnAfterInitSourceDocument(WhseActivHeader);
    end;

    LOCAL procedure UpdateSourceDocument()
    var
        SalesLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
    begin
        OnBeforeUpdateSourceDocument(TempWhseActivLine);

        WITH TempWhseActivLine DO
            CASE "Source Type" OF
                DATABASE::"Purchase Line":
                    BEGIN
                        IF "Activity Type" = "Activity Type"::"Invt. Pick" THEN BEGIN
                            "Qty. to Handle" := -"Qty. to Handle";
                            "Qty. to Handle (Base)" := -"Qty. to Handle (Base)";
                        END;
                        PurchLine.GET("Source Subtype", "Source No.", "Source Line No.");
                        IF "Source Document" = "Source Document"::"Purchase Order" THEN BEGIN
                            // SEC - to support partial put away with serial
                            //>>>
                            //PurchLine.VALIDATE("Qty. to Receive", "Qty. to Handle");
                            //PurchLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                            //PurchLine.validate("Qty. to Receive", (PurchLine."Qty. to Receive" + "Qty. to Handle"));
                            PurchLine.validate("Qty. to Receive (Base)", (PurchLine."Qty. to Receive (Base)" + "Qty. to Handle (Base)"));
                            //<<<                      
                            IF InvoiceSourceDoc THEN
                                PurchLine.VALIDATE("Qty. to Invoice", "Qty. to Handle");
                        END ELSE BEGIN
                            PurchLine.VALIDATE("Return Qty. to Ship", -"Qty. to Handle");
                            PurchLine."Return Qty. to Ship (Base)" := -"Qty. to Handle (Base)";
                            IF InvoiceSourceDoc THEN
                                PurchLine.VALIDATE("Qty. to Invoice", -"Qty. to Handle");
                        END;
                        PurchLine."Bin Code" := "Bin Code";
                        PurchLine.MODIFY;
                        OnAfterPurchLineModify(PurchLine);
                        OnUpdateSourceDocumentOnAfterPurchLineModify(PurchLine, TempWhseActivLine);
                    END;
                DATABASE::"Sales Line":
                    BEGIN
                        IF "Activity Type" = "Activity Type"::"Invt. Pick" THEN BEGIN
                            "Qty. to Handle" := -"Qty. to Handle";
                            "Qty. to Handle (Base)" := -"Qty. to Handle (Base)";
                        END;
                        SalesLine.GET("Source Subtype", "Source No.", "Source Line No.");
                        IF "Source Document" = "Source Document"::"Sales Order" THEN BEGIN
                            SalesLine.VALIDATE("Qty. to Ship", -"Qty. to Handle");
                            SalesLine."Qty. to Ship (Base)" := -"Qty. to Handle (Base)";
                            IF InvoiceSourceDoc THEN
                                SalesLine.VALIDATE("Qty. to Invoice", -"Qty. to Handle");
                        END ELSE BEGIN
                            SalesLine.VALIDATE("Return Qty. to Receive", "Qty. to Handle");
                            SalesLine."Return Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                            IF InvoiceSourceDoc THEN
                                SalesLine.VALIDATE("Qty. to Invoice", "Qty. to Handle");
                        END;
                        SalesLine."Bin Code" := "Bin Code";
                        SalesLine.MODIFY;
                        IF "Assemble to Order" THEN BEGIN
                            ATOLink.UpdateQtyToAsmFromInvtPickLine(TempWhseActivLine);
                            ATOLink.UpdateAsmBinCodeFromInvtPickLine(TempWhseActivLine);
                        END;
                        OnAfterSalesLineModify(SalesLine);
                        OnUpdateSourceDocumentOnAfterSalesLineModify(SalesLine, TempWhseActivLine);
                    END;
                DATABASE::"Transfer Line":
                    BEGIN
                        TransLine.GET("Source No.", "Source Line No.");
                        IF "Activity Type" = "Activity Type"::"Invt. Put-away" THEN BEGIN
                            TransLine."Transfer-To Bin Code" := "Bin Code";
                            TransLine.VALIDATE("Qty. to Receive", "Qty. to Handle");
                            TransLine."Qty. to Receive (Base)" := "Qty. to Handle (Base)";
                        END ELSE BEGIN
                            TransLine."Transfer-from Bin Code" := "Bin Code";
                            TransLine.VALIDATE("Qty. to Ship", "Qty. to Handle");
                            TransLine."Qty. to Ship (Base)" := "Qty. to Handle (Base)";
                        END;
                        TransLine.MODIFY;
                        OnUpdateSourceDocumentOnAfterTransLineModify(TransLine, TempWhseActivLine);
                    END;
            END;
    end;

    LOCAL procedure UpdateUnhandledTransLine(TransHeaderNo: Code[20])
    begin
        WITH TransLine DO BEGIN
            SETRANGE("Document No.", TransHeaderNo);
            SETRANGE("Derived From Line No.", 0);
            SETRANGE("Qty. to Ship", 0);
            SETRANGE("Qty. to Receive", 0);
            IF FINDSET THEN
                REPEAT
                    IF "Qty. in Transit" <> 0 THEN
                        VALIDATE("Qty. to Receive", "Qty. in Transit");
                    IF "Outstanding Quantity" <> 0 THEN
                        VALIDATE("Qty. to Ship", "Outstanding Quantity");
                    MODIFY;
                UNTIL NEXT = 0;
        END;
    end;

    LOCAL procedure PostSourceDocument(WhseActivHeader: Record "Warehouse Activity Header")
    var
        PurchPost: Codeunit "Purch.-Post";
        SalesPost: Codeunit "Sales-Post";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferPostShip: Codeunit "TransferOrder-Post Shipment";
    begin
        WITH WhseActivHeader DO
            CASE "Source Type" OF
                DATABASE::"Purchase Line":
                    BEGIN
                        CLEAR(PurchPost);
                        COMMIT;
                        IF "Source Document" = "Source Document"::"Purchase Order" THEN
                            PurchHeader.Receive := TRUE
                        ELSE
                            PurchHeader.Ship := TRUE;
                        PurchHeader.Invoice := InvoiceSourceDoc;
                        PurchHeader."Posting from Whse. Ref." := PostingReference;
                        //SEC - added to set receive on header in codeunit 90
                        //>>>
                        PurchHeader.Modify(false);
                        //<<<
                        PurchPost.RUN(PurchHeader);
                        IF "Source Document" = "Source Document"::"Purchase Order" THEN BEGIN
                            PostedSourceType := DATABASE::"Purch. Rcpt. Header";
                            PostedSourceNo := PurchHeader."Last Receiving No.";
                        END ELSE BEGIN
                            PostedSourceType := DATABASE::"Return Shipment Header";
                            PostedSourceNo := PurchHeader."Last Return Shipment No.";
                        END;
                        PostedSourceSubType := 0;
                    END;
                DATABASE::"Sales Line":
                    BEGIN
                        CLEAR(SalesPost);
                        COMMIT;
                        IF "Source Document" = "Source Document"::"Sales Order" THEN
                            SalesHeader.Ship := TRUE
                        ELSE
                            SalesHeader.Receive := TRUE;
                        SalesHeader.Invoice := InvoiceSourceDoc;
                        SalesHeader."Posting from Whse. Ref." := PostingReference;
                        SalesPost.SetWhseJnlRegisterCU(WhseJnlRegisterLine);
                        SalesPost.RUN(SalesHeader);
                        IF "Source Document" = "Source Document"::"Sales Order" THEN BEGIN
                            PostedSourceType := DATABASE::"Sales Shipment Header";
                            PostedSourceNo := SalesHeader."Last Shipping No.";
                        END ELSE BEGIN
                            PostedSourceType := DATABASE::"Return Receipt Header";
                            PostedSourceNo := SalesHeader."Last Return Receipt No.";
                        END;
                        PostedSourceSubType := 0;
                    END;
                DATABASE::"Transfer Line":
                    BEGIN
                        CLEAR(TransferPostReceipt);
                        COMMIT;
                        IF Type = Type::"Invt. Put-away" THEN BEGIN
                            IF HideDialog THEN
                                TransferPostReceipt.SetHideValidationDialog(HideDialog);
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            TransferPostReceipt.RUN(TransHeader);
                            PostedSourceType := DATABASE::"Transfer Receipt Header";
                            PostedSourceNo := TransHeader."Last Receipt No.";
                        END ELSE BEGIN
                            IF HideDialog THEN
                                TransferPostShip.SetHideValidationDialog(HideDialog);
                            TransHeader."Posting from Whse. Ref." := PostingReference;
                            TransferPostShip.RUN(TransHeader);
                            PostedSourceType := DATABASE::"Transfer Shipment Header";
                            PostedSourceNo := TransHeader."Last Shipment No.";
                        END;
                        UpdateUnhandledTransLine(TransHeader."No.");
                        PostedSourceSubType := 0;
                    END;
            END;
    end;

    LOCAL procedure PostWhseJnlLine(WhseActivLine: Record "Warehouse Activity Line")
    var
        TempWhseJnlLine: Record "Warehouse Journal Line";
        WMSMgt: Codeunit "WMS Management";
    begin
        CreateWhseJnlLine(TempWhseJnlLine, WhseActivLine);
        IF TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." THEN
            WMSMgt.CheckWhseJnlLine(TempWhseJnlLine, 4, TempWhseJnlLine."Qty. (Base)", FALSE); // 4 = Whse. Journal
        WhseJnlRegisterLine.RUN(TempWhseJnlLine);
    end;

    LOCAL procedure CreateWhseJnlLine(VAR WhseJnlLine: Record "Warehouse Journal Line"; WhseActivLine: Record "Warehouse Activity Line")
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        WITH WhseActivLine DO BEGIN
            WhseJnlLine.INIT;
            WhseJnlLine."Location Code" := "Location Code";
            WhseJnlLine."Item No." := "Item No.";
            WhseJnlLine."Registering Date" := WhseActivHeader."Posting Date";
            WhseJnlLine."User ID" := USERID;
            WhseJnlLine."Variant Code" := "Variant Code";
            IF "Action Type" = "Action Type"::Take THEN BEGIN
                WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";
                WhseJnlLine."From Bin Code" := "Bin Code";
                WhseJnlLine.Quantity := "Qty. to Handle (Base)";
                WhseJnlLine."Qty. (Base)" := "Qty. to Handle (Base)";
            END ELSE BEGIN
                WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                WhseJnlLine."To Bin Code" := "Bin Code";
                WhseJnlLine.Quantity := -"Qty. to Handle (Base)";
                WhseJnlLine."Qty. (Base)" := -"Qty. to Handle (Base)";
            END;
            WhseJnlLine."Qty. (Absolute)" := "Qty. to Handle (Base)";
            WhseJnlLine."Qty. (Absolute, Base)" := "Qty. to Handle (Base)";
            WhseJnlLine."Unit of Measure Code" := WMSMgt.GetBaseUOM("Item No.");
            WhseJnlLine."Qty. per Unit of Measure" := 1;
            WhseJnlLine."Source Type" := PostedSourceType;
            WhseJnlLine."Source Subtype" := PostedSourceSubType;
            WhseJnlLine."Source No." := PostedSourceNo;
            WhseJnlLine."Reference No." := PostedSourceNo;
            CASE "Source Document" OF
                "Source Document"::"Purchase Order":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rcpt.";
                    END;
                "Source Document"::"Sales Order":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Shipment";
                    END;
                "Source Document"::"Purchase Return Order":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup.Purchases;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Shipment";
                    END;
                "Source Document"::"Sales Return Order":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup.Sales;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted Rtrn. Rcpt.";
                    END;
                "Source Document"::"Outbound Transfer":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Shipment";
                    END;
                "Source Document"::"Inbound Transfer":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup.Transfer;
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Posted T. Receipt";
                    END;
                "Source Document"::"Prod. Consumption":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
                    END;
                "Source Document"::"Prod. Output":
                    BEGIN
                        WhseJnlLine."Source Code" := SourceCodeSetup."Output Journal";
                        WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
                    END;
            END;

            IF "Activity Type" IN ["Activity Type"::"Invt. Put-away", "Activity Type"::"Invt. Pick",
                                   "Activity Type"::"Invt. Movement"]
            THEN
                WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";

            WhseJnlLine."Serial No." := "Serial No.";
            WhseJnlLine."Lot No." := "Lot No.";
            WhseJnlLine."Warranty Date" := "Warranty Date";
            WhseJnlLine."Expiration Date" := "Expiration Date";
        END;

        OnAfterCreateWhseJnlLine(WhseJnlLine, WhseActivLine);
    end;

    LOCAL procedure CreatePostedActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
    var
        WhseComment: Record "Warehouse Comment Line";
        WhseComment2: Record "Warehouse Comment Line";
    begin
        IF WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" THEN BEGIN
            PostedInvtPutAwayHdr.INIT;
            PostedInvtPutAwayHdr.TRANSFERFIELDS(WhseActivHeader);
            PostedInvtPutAwayHdr."No." := '';
            PostedInvtPutAwayHdr."Invt. Put-away No." := WhseActivHeader."No.";
            PostedInvtPutAwayHdr."Source No." := PostedSourceNo;
            PostedInvtPutAwayHdr."Source Type" := PostedSourceType;
            PostedInvtPutAwayHdr.INSERT(TRUE);
        END ELSE BEGIN
            PostedInvtPickHdr.INIT;
            PostedInvtPickHdr.TRANSFERFIELDS(WhseActivHeader);
            PostedInvtPickHdr."No." := '';
            PostedInvtPickHdr."Invt Pick No." := WhseActivHeader."No.";
            PostedInvtPickHdr."Source No." := PostedSourceNo;
            PostedInvtPickHdr."Source Type" := PostedSourceType;
            PostedInvtPickHdr.INSERT(TRUE);
        END;

        WhseComment.SETRANGE("Table Name", WhseComment."Table Name"::"Whse. Activity Header");
        WhseComment.SETRANGE(Type, WhseActivHeader.Type);
        WhseComment.SETRANGE("No.", WhseActivHeader."No.");
        WhseComment.LOCKTABLE;
        IF WhseComment.FIND('-') THEN
            REPEAT
                WhseComment2.INIT;
                WhseComment2 := WhseComment;
                IF WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" THEN BEGIN
                    WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Invt. Put-Away";
                    WhseComment2."No." := PostedInvtPutAwayHdr."No.";
                END ELSE BEGIN
                    WhseComment2."Table Name" := WhseComment2."Table Name"::"Posted Invt. Pick";
                    WhseComment2."No." := PostedInvtPickHdr."No.";
                END;
                WhseComment2.Type := WhseComment2.Type::" ";
                WhseComment2.INSERT;
            UNTIL WhseComment.NEXT = 0;
    end;

    LOCAL procedure CreatePostedActivLine(WhseActivLine: Record "Warehouse Activity Line")
    begin
        IF WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Put-away" THEN BEGIN
            PostedInvtPutAwayLine.INIT;
            PostedInvtPutAwayLine.TRANSFERFIELDS(WhseActivLine);
            PostedInvtPutAwayLine."No." := PostedInvtPutAwayHdr."No.";
            PostedInvtPutAwayLine.VALIDATE(Quantity, WhseActivLine."Qty. to Handle");
            PostedInvtPutAwayLine.INSERT;
        END ELSE BEGIN
            PostedInvtPickLine.INIT;
            PostedInvtPickLine.TRANSFERFIELDS(WhseActivLine);
            PostedInvtPickLine."No." := PostedInvtPickHdr."No.";
            PostedInvtPickLine.VALIDATE(Quantity, WhseActivLine."Qty. to Handle");
            PostedInvtPickLine.INSERT;
        END;
    end;

    LOCAL procedure PostSourceDoc()
    begin
        TempWhseActivLine.RESET;
        TempWhseActivLine.SetRange("Source No.", WhseActivHeader."Source No.");
        TempWhseActivLine.setrange("Source type", WhseActivHeader."Source type");
        TempWhseActivLine.FIND('-');
        InitSourceDocument;
        REPEAT
            UpdateSourceDocument;
        UNTIL TempWhseActivLine.NEXT = 0;

        PostSourceDocument(WhseActivHeader);
    end;

    LOCAL procedure PostConsumption()
    begin
        WITH TempWhseActivLine DO BEGIN
            RESET;
            FIND('-');
            ProdOrder.GET("Source Subtype", "Source No.");
            REPEAT
                ProdOrderComp.GET("Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                PostConsumptionLine;
            UNTIL NEXT = 0;

            PostedSourceType := "Source Type";
            PostedSourceSubType := "Source Subtype";
            PostedSourceNo := "Source No.";
        END;
    end;

    LOCAL procedure PostConsumptionLine()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
    begin
        WITH TempWhseActivLine DO BEGIN
            ProdOrderLine.GET("Source Subtype", "Source No.", "Source Line No.");
            ItemJnlLine.INIT;
            ItemJnlLine.VALIDATE("Entry Type", ItemJnlLine."Entry Type"::Consumption);
            ItemJnlLine.VALIDATE("Posting Date", WhseActivHeader."Posting Date");
            ItemJnlLine."Source No." := ProdOrderLine."Item No.";
            ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
            ItemJnlLine."Document No." := ProdOrder."No.";
            ItemJnlLine.VALIDATE("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.", ProdOrder."No.");
            ItemJnlLine.VALIDATE("Order Line No.", ProdOrderLine."Line No.");
            ItemJnlLine.VALIDATE("Item No.", "Item No.");
            IF ItemJnlLine."Unit of Measure Code" <> "Unit of Measure Code" THEN
                ItemJnlLine.VALIDATE("Unit of Measure Code", "Unit of Measure Code");
            ItemJnlLine.VALIDATE("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine.Description := Description;
            IF "Activity Type" = "Activity Type"::"Invt. Pick" THEN
                ItemJnlLine.VALIDATE(Quantity, "Qty. to Handle")
            ELSE
                ItemJnlLine.VALIDATE(Quantity, -"Qty. to Handle");
            ItemJnlLine.VALIDATE("Unit Cost", ProdOrderComp."Unit Cost");
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
            ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
            GetItem("Item No.");
            ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
            OnPostConsumptionLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine);
            ReserveProdOrderComp.TransferPOCompToItemJnlLine(ProdOrderComp, ItemJnlLine, ItemJnlLine."Quantity (Base)");
            ItemJnlPostLine.SetCalledFromInvtPutawayPick(TRUE);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            ReserveProdOrderComp.UpdateItemTrackingAfterPosting(ProdOrderComp);
        END;
    end;

    LOCAL procedure PostOutput()
    begin
        WITH TempWhseActivLine DO BEGIN
            RESET;
            FIND('-');
            ProdOrder.GET("Source Subtype", "Source No.");
            REPEAT
                ProdOrderLine.GET("Source Subtype", "Source No.", "Source Line No.");
                PostOutputLine;
            UNTIL NEXT = 0;
            PostedSourceType := "Source Type";
            PostedSourceSubType := "Source Subtype";
            PostedSourceNo := "Source No.";
        END;
    end;

    LOCAL procedure PostOutputLine()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ReservProdOrderLine: Codeunit "Prod. Order Line-Reserve";
    begin
        WITH TempWhseActivLine DO BEGIN
            ItemJnlLine.INIT;
            ItemJnlLine.VALIDATE("Entry Type", ItemJnlLine."Entry Type"::Output);
            ItemJnlLine.VALIDATE("Posting Date", WhseActivHeader."Posting Date");
            ItemJnlLine."Document No." := ProdOrder."No.";
            ItemJnlLine.VALIDATE("Order Type", ItemJnlLine."Order Type"::Production);
            ItemJnlLine.VALIDATE("Order No.", ProdOrder."No.");
            ItemJnlLine.VALIDATE("Order Line No.", ProdOrderLine."Line No.");
            ItemJnlLine.VALIDATE("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ItemJnlLine.VALIDATE("Routing No.", ProdOrderLine."Routing No.");
            ItemJnlLine.VALIDATE("Item No.", ProdOrderLine."Item No.");
            IF ItemJnlLine."Unit of Measure Code" <> "Unit of Measure Code" THEN
                ItemJnlLine.VALIDATE("Unit of Measure Code", "Unit of Measure Code");
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine.Description := Description;
            IF ProdOrderLine."Routing No." <> '' THEN
                ItemJnlLine.VALIDATE("Operation No.", CalcLastOperationNo);
            ItemJnlLine.VALIDATE("Output Quantity", "Qty. to Handle");
            ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
            ItemJnlLine."Dimension Set ID" := ProdOrderLine."Dimension Set ID";
            ReservProdOrderLine.TransferPOLineToItemJnlLine(
              ProdOrderLine, ItemJnlLine, ItemJnlLine."Quantity (Base)");
            ItemJnlPostLine.SetCalledFromInvtPutawayPick(TRUE);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            ReservProdOrderLine.UpdateItemTrackingAfterPosting(ProdOrderLine);
        END;
    end;

    LOCAL procedure CalcLastOperationNo(): Code[10]
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRouteManagement: Codeunit "Prod. Order Route Management";
    begin
        WITH ProdOrderLine DO BEGIN
            ProdOrderRtngLine.SETRANGE(Status, Status);
            ProdOrderRtngLine.SETRANGE("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SETRANGE("Routing Reference No.", "Routing Reference No.");
            ProdOrderRtngLine.SETRANGE("Routing No.", "Routing No.");
            IF NOT ProdOrderRtngLine.ISEMPTY THEN BEGIN
                ProdOrderRouteManagement.Check(ProdOrderLine);
                ProdOrderRtngLine.SETRANGE("Next Operation No.", '');
                ProdOrderRtngLine.FINDLAST;
                EXIT(ProdOrderRtngLine."Operation No.");
            END;

            EXIT('');
        END;
    end;

    LOCAL procedure GetLocation(LocationCode: Code[10])
    begin
        IF LocationCode = '' THEN
            CLEAR(Location)
        ELSE
            IF Location.Code <> LocationCode THEN
                Location.GET(LocationCode);
    end;

    LOCAL procedure GetItem(ItemNo: Code[20])
    begin
        IF Item."No." <> ItemNo THEN
            Item.GET(ItemNo);
    end;

    procedure ShowHideDialog(HideDialog2: Boolean)
    begin
        HideDialog := HideDialog2;
    end;

    procedure SetInvoiceSourceDoc(Invoice: Boolean)
    begin
        InvoiceSourceDoc := Invoice;
    end;

    procedure PrintDocument(SetPrint: Boolean)
    begin
        PrintDoc := SetPrint;
    end;

    LOCAL procedure CheckItemTracking(WhseActivLine2: Record "Warehouse Activity Line"): Boolean
    var
        SNRequired: Boolean;
        LNRequired: Boolean;
    begin
        WITH WhseActivLine2 DO BEGIN
            ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.", SNRequired, LNRequired, FALSE);
            IF SNRequired THEN
                TESTFIELD("Serial No.");
            IF LNRequired THEN
                TESTFIELD("Lot No.");
        END;

        EXIT(SNRequired OR LNRequired);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterInitSourceDocument(VAR WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateWhseJnlLine(VAR WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterSalesLineModify(VAR SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPurchLineModify(VAR PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterTransLineModify(VAR TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterWhseActivLineModify(VAR WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCodeOnAfterCreatePostedWhseActivDocument(VAR WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertTempWhseActivLine(VAR WhseActivLine: Record "Warehouse Activity Line"; ItemTrackingRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeInitSourceDocument(VAR WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCheckLines(VAR WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeUpdateSourceDocument(VAR TempWhseActivLine: Record "Warehouse Activity Line" TEMPORARY)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeWhseActivLineDelete(WarehouseActivityLine: Record "Warehouse Activity Line"; VAR ForceDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnPostConsumptionLineOnAfterCreateItemJnlLine(VAR ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin

    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateSourceDocumentOnAfterPurchLineModify(VAR PurchaseLine: Record "Purchase Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin

    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateSourceDocumentOnAfterSalesLineModify(VAR SalesLine: Record "Sales Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin

    end;

    [IntegrationEvent(false, false)]
    procedure OnUpdateSourceDocumentOnAfterTransLineModify(VAR TransferLine: Record "Transfer Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin

    end;

    var
        Location: Record Location;
        Item: Record Item;
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line";
        PostedInvtPutAwayHdr: Record "Posted Invt. Put-away Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PostedInvtPickHdr: Record "Posted Invt. Pick Header";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        WhseSetup: Record "Warehouse Setup";
        WhseRequest: Record "Warehouse Request";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        SourceCodeSetup: Record "Source Code Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        PurchPostPrint: Codeunit "Purch.-Post + Print";
        SalesPostPrint: Codeunit "Sales-Post + Print";
        Window: Dialog;
        PostedSourceNo: Code[20];
        PostedSourceType: Integer;
        PostedSourceSubType: Integer;
        NoOfRecords: Integer;
        LineCount: Integer;
        PostingReference: Integer;
        HideDialog: Boolean;
        InvoiceSourceDoc: Boolean;
        PrintDoc: Boolean;

}