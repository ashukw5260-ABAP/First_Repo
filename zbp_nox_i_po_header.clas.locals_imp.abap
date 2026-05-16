CLASS lhc_header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    " EARLY NUMBERING for Header (PoId) - REQUIRED because BDEF has early numbering
    METHODS earlynumbering_header FOR NUMBERING
      IMPORTING entities FOR CREATE Header.

    METHODS earlynumbering_cba_items FOR NUMBERING
      IMPORTING entities FOR CREATE Header\_Items.

    METHODS setstatusnew FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Header~SetStatusNew.

    METHODS validatecompanycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR Header~ValidateCompanyCode.

    METHODS validatesupplier FOR VALIDATE ON SAVE
      IMPORTING keys FOR Header~ValidateSupplier.

ENDCLASS.

CLASS lhc_header IMPLEMENTATION.

  METHOD earlynumbering_header.


    LOOP AT entities INTO DATA(ls_create).

      TRY.
         DATA(lv_poid) = cl_system_uuid=>CREATE_UUID_C32_STATIC( ).

          APPEND VALUE #(
            %cid = ls_create-%cid
            PoId = lv_poid
          ) TO mapped-header.

        CATCH cx_root INTO DATA(lx).
          "If key can't be generated, mark instance as failed (also prevents dump)
          APPEND VALUE #(
            %cid  = ls_create-%cid
            %fail-cause = if_abap_behv=>cause-unspecific
          ) TO failed-header.

          APPEND VALUE #(
            %cid = ls_create-%cid
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = lx->get_text( ) )
          ) TO reported-header.
      ENDTRY.

    ENDLOOP.
  ENDMETHOD.

  METHOD setstatusnew.
    READ ENTITIES OF znox_i_po_header IN LOCAL MODE
      ENTITY Header
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    DATA lt_update TYPE TABLE FOR UPDATE znox_i_po_header.

    LOOP AT lt_headers INTO DATA(ls_header).
      IF ls_header-Status IS INITIAL.
        APPEND VALUE #(
          %tky            = ls_header-%tky
          Status          = 'NEW'
          %control-Status = if_abap_behv=>mk-on
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF znox_i_po_header IN LOCAL MODE
        ENTITY Header
          UPDATE FIELDS ( Status )
          WITH lt_update
        REPORTED DATA(lt_reported).

      reported = CORRESPONDING #( DEEP lt_reported ).
    ENDIF.
  ENDMETHOD.

  METHOD earlynumbering_cba_items.

    DATA: lv_max_active_numc TYPE n LENGTH 5,
          lv_max_draft_numc  TYPE n LENGTH 5,
          lv_next_i          TYPE i.

    LOOP AT entities INTO DATA(ls_header_entity).
      DATA(lv_po_id) = ls_header_entity-PoId.

      SELECT MAX( item_id )
        FROM znox_po_item
        WHERE po_id = @lv_po_id
        INTO @lv_max_active_numc.

      SELECT MAX( itemid )
        FROM znox_d_po_item
        WHERE poid = @lv_po_id
        INTO @lv_max_draft_numc.

      DATA(lv_max_active_i) = COND i(
        WHEN lv_max_active_numc IS INITIAL THEN 0
        ELSE CONV i( lv_max_active_numc )
      ).

      DATA(lv_max_draft_i) = COND i(
        WHEN lv_max_draft_numc IS INITIAL THEN 0
        ELSE CONV i( lv_max_draft_numc )
      ).

      lv_next_i = COND i(
        WHEN lv_max_draft_i > lv_max_active_i THEN lv_max_draft_i
        ELSE lv_max_active_i
      ).

      LOOP AT ls_header_entity-%target INTO DATA(ls_item_create).
        lv_next_i = lv_next_i + 1.

        APPEND VALUE #(
          %cid   = ls_item_create-%cid
          PoId   = lv_po_id
          ItemId = |{ lv_next_i WIDTH = 5 PAD = '0' }|
        ) TO mapped-item.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD validatecompanycode.
    READ ENTITIES OF znox_i_po_header IN LOCAL MODE
      ENTITY Header
        FIELDS ( CompanyCode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    LOOP AT lt_headers INTO DATA(ls_header).
      IF ls_header-CompanyCode IS INITIAL.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-header.
        APPEND VALUE #(
          %tky                 = ls_header-%tky
          %element-CompanyCode = if_abap_behv=>mk-on
          %msg                 = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = 'Company Code must not be empty' )
        ) TO reported-header.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatesupplier.
    READ ENTITIES OF znox_i_po_header IN LOCAL MODE
      ENTITY Header
        FIELDS ( Supplier )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_headers).

    LOOP AT lt_headers INTO DATA(ls_header).
      IF ls_header-Supplier IS INITIAL.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-header.
        APPEND VALUE #(
          %tky              = ls_header-%tky
          %element-Supplier = if_abap_behv=>mk-on
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Supplier must not be empty' )
        ) TO reported-header.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS defaultcurrency FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Item~DefaultCurrency.

    METHODS validatequantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ValidateQuantity.

    METHODS validatenetprice FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ValidateNetPrice.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD defaultcurrency.
    READ ENTITIES OF znox_i_po_header IN LOCAL MODE
      ENTITY Item
        FIELDS ( PoId Currency )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA lt_update TYPE TABLE FOR UPDATE znox_i_po_item.

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-Currency IS INITIAL.

        READ ENTITIES OF znox_i_po_header IN LOCAL MODE
          ENTITY Header
            FIELDS ( Currency )
            WITH VALUE #( ( PoId = ls_item-PoId ) )
          RESULT DATA(lt_headers).

        READ TABLE lt_headers INTO DATA(ls_header) INDEX 1.
        IF sy-subrc = 0 AND ls_header-Currency IS NOT INITIAL.
          APPEND VALUE #(
            %tky              = ls_item-%tky
            Currency          = ls_header-Currency
            %control-Currency = if_abap_behv=>mk-on
          ) TO lt_update.
        ENDIF.

        CLEAR lt_headers.
      ENDIF.
    ENDLOOP.

    IF lt_update IS NOT INITIAL.
      MODIFY ENTITIES OF znox_i_po_header IN LOCAL MODE
        ENTITY Item
          UPDATE FIELDS ( Currency )
          WITH lt_update
        REPORTED DATA(lt_reported).

      reported = CORRESPONDING #( DEEP lt_reported ).
    ENDIF.
  ENDMETHOD.

  METHOD validatequantity.
    READ ENTITIES OF znox_i_po_header IN LOCAL MODE
      ENTITY Item
        FIELDS ( Quantity )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-Quantity <= 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-item.
        APPEND VALUE #(
          %tky              = ls_item-%tky
          %element-Quantity = if_abap_behv=>mk-on
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Quantity must be greater than 0' )
        ) TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validatenetprice.
    READ ENTITIES OF znox_i_po_header IN LOCAL MODE
      ENTITY Item
        FIELDS ( NetPrice )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-NetPrice < 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-item.
        APPEND VALUE #(
          %tky              = ls_item-%tky
          %element-NetPrice = if_abap_behv=>mk-on
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Net Price must not be negative' )
        ) TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
