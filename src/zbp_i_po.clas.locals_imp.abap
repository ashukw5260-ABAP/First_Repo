CLASS lcl_buffer IMPLEMENTATION.

  METHOD add_create_po.
    INSERT is_po INTO TABLE mt_create_po.
  ENDMETHOD.

  METHOD add_update_po.
    INSERT is_po INTO TABLE mt_update_po.
  ENDMETHOD.

  METHOD add_delete_po.
    INSERT is_po INTO TABLE mt_delete_po.
  ENDMETHOD.

  METHOD add_create_item.
    INSERT is_item INTO TABLE mt_create_item.
  ENDMETHOD.

  METHOD add_update_item.
    INSERT is_item INTO TABLE mt_update_item.
  ENDMETHOD.

  METHOD add_delete_item.
    INSERT is_item INTO TABLE mt_delete_item.
  ENDMETHOD.

  METHOD get_create_po.
    rt_result = mt_create_po.
  ENDMETHOD.

  METHOD get_update_po.
    rt_result = mt_update_po.
  ENDMETHOD.

  METHOD get_delete_po.
    rt_result = mt_delete_po.
  ENDMETHOD.

  METHOD get_create_item.
    rt_result = mt_create_item.
  ENDMETHOD.

  METHOD get_update_item.
    rt_result = mt_update_item.
  ENDMETHOD.

  METHOD get_delete_item.
    rt_result = mt_delete_item.
  ENDMETHOD.

  METHOD clear_all.
    CLEAR: mt_create_po, mt_update_po, mt_delete_po,
           mt_create_item, mt_update_item, mt_delete_item.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_po IMPLEMENTATION.

  METHOD create_po.
    DATA: ls_po     TYPE zpo_hdr,
          lv_exists TYPE xsdboolean.

    LOOP AT entities INTO DATA(ls_entity).
      " Validate mandatory key
      IF ls_entity-po_id IS INITIAL.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '001'
                              v1 = 'PO_ID' )
        ) TO reported-po.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po.
        CONTINUE.
      ENDIF.

      " Check for duplicate in DB
      SELECT SINGLE @abap_true INTO lv_exists
        FROM zpo_hdr
        WHERE mandt = @sy-mandt
          AND po_id = @ls_entity-po_id.

      IF lv_exists = abap_true.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '002'
                              v1 = ls_entity-po_id )
        ) TO reported-po.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po.
        CONTINUE.
      ENDIF.

      " Prepare record for insert
      ls_po             = CORRESPONDING #( ls_entity ).
      ls_po-mandt       = sy-mandt.
      ls_po-is_deleted  = ' '.
      ls_po-created_by  = sy-uname.
      ls_po-created_at  = utclong_now( ).
      ls_po-changed_by  = sy-uname.
      ls_po-changed_at  = utclong_now( ).

      " Add to create buffer via controlled accessor
      lcl_buffer=>add_create_po( ls_po ).

      " Set mapped
      APPEND VALUE #(
        %cid  = ls_entity-%cid
        po_id = ls_entity-po_id
      ) TO mapped-po.
    ENDLOOP.
  ENDMETHOD.

  METHOD update_po.
    DATA: ls_po TYPE zpo_hdr.

    LOOP AT entities INTO DATA(ls_entity).
      " Check if PO exists and is not soft-deleted
      SELECT SINGLE @abap_true INTO DATA(lv_exists)
        FROM zpo_hdr
        WHERE mandt      = @sy-mandt
          AND po_id      = @ls_entity-po_id
          AND is_deleted = ' '.

      IF lv_exists IS NOT TRUE.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '003'
                              v1 = ls_entity-po_id )
        ) TO reported-po.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po.
        CONTINUE.
      ENDIF.

      " Prepare record for update
      ls_po            = CORRESPONDING #( ls_entity ).
      ls_po-mandt      = sy-mandt.
      ls_po-changed_by = sy-uname.
      ls_po-changed_at = utclong_now( ).

      " Add to update buffer via controlled accessor
      lcl_buffer=>add_update_po( ls_po ).

      " Set mapped
      APPEND VALUE #(
        %cid  = ls_entity-%cid
        po_id = ls_entity-po_id
      ) TO mapped-po.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_po.
    DATA: ls_delete TYPE zpo_hdr.

    LOOP AT entities INTO DATA(ls_entity).
      " Prepare for logical delete
      ls_delete-mandt = sy-mandt.
      ls_delete-po_id = ls_entity-po_id.

      " Add to delete buffer via controlled accessor
      lcl_buffer=>add_delete_po( ls_delete ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read_po.
    DATA: lt_result TYPE TABLE OF zi_po.

    " Read from CDS view (which already filters IS_DELETED = ' ')
    SELECT po_id, vendor_id, doc_date, currency, status,
           created_by, created_at, changed_by, changed_at
      FROM zi_po
      FOR ALL ENTRIES IN @keys
      WHERE po_id = @keys-po_id
      INTO CORRESPONDING FIELDS OF TABLE @lt_result.

    LOOP AT keys INTO DATA(ls_key) ASSIGNING FIELD-SYMBOL(<key>).
      DATA(lv_idx) = sy-tabix.
      READ TABLE lt_result INTO DATA(ls_data)
        WITH KEY po_id = ls_key-po_id.
      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_data ) TO result INDEX lv_idx.
      ELSE.
        APPEND INITIAL LINE TO result INDEX lv_idx.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD create_items.
    DATA: ls_item      TYPE zpo_itm,
          lv_po_exists TYPE xsdboolean.

    LOOP AT entities INTO DATA(ls_entity).
      " Check if parent PO exists and is not soft-deleted
      SELECT SINGLE @abap_true INTO lv_po_exists
        FROM zpo_hdr
        WHERE mandt      = @sy-mandt
          AND po_id      = @ls_entity-po_id
          AND is_deleted = ' '.

      IF lv_po_exists IS NOT TRUE.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '004'
                              v1 = ls_entity-po_id )
        ) TO reported-po_item.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po_item.
        CONTINUE.
      ENDIF.

      " Validate item number
      IF ls_entity-item_no IS INITIAL.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '005'
                              v1 = 'ITEM_NO' )
        ) TO reported-po_item.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po_item.
        CONTINUE.
      ENDIF.

      " Prepare item for insert
      ls_item            = CORRESPONDING #( ls_entity ).
      ls_item-mandt      = sy-mandt.
      ls_item-is_deleted = ' '.
      ls_item-created_by = sy-uname.
      ls_item-created_at = utclong_now( ).
      ls_item-changed_by = sy-uname.
      ls_item-changed_at = utclong_now( ).

      " Add to create buffer via controlled accessor
      lcl_buffer=>add_create_item( ls_item ).

      " Set mapped
      APPEND VALUE #(
        %cid    = ls_entity-%cid
        po_id   = ls_entity-po_id
        item_no = ls_entity-item_no
      ) TO mapped-po_item.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_items.
    " Read items by association – CDS view already filters IS_DELETED = ' '
    SELECT po_id, item_no, material, quantity, uom, net_price,
           currency, plant, created_by, created_at, changed_by, changed_at
      FROM zi_po_item
      FOR ALL ENTRIES IN @keys_for_tabname
      WHERE po_id = @keys_for_tabname-po_id
      INTO TABLE @DATA(lt_items).

    LOOP AT keys_for_tabname INTO DATA(ls_key).
      LOOP AT lt_items INTO DATA(ls_item)
        WHERE po_id = ls_key-po_id.
        APPEND CORRESPONDING #( ls_item ) TO result.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_po.
    " Lock master: in production, lock object EZPO_HDR should be invoked here.
    " The RAP framework handles optimistic concurrency via the etag field CHANGED_AT.
  ENDMETHOD.

  METHOD global_authorization.
    " Grant all operations – replace with proper authority-check calls in production.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD validate_vendor_id.
    " Read the VENDOR_ID field for all incoming keys
    READ ENTITIES OF zi_po IN LOCAL MODE
      ENTITY po
        FIELDS ( vendor_id )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pos)
      FAILED DATA(lt_failed).

    LOOP AT lt_pos INTO DATA(ls_po).
      IF ls_po-vendor_id IS INITIAL.
        APPEND VALUE #( %tky = ls_po-%tky ) TO failed-po.
        APPEND VALUE #(
          %tky           = ls_po-%tky
          %element-vendor_id = if_abap_behv=>mk-on
          %msg           = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = 'Vendor ID must not be empty' )
        ) TO reported-po.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_currency.
    " Read the CURRENCY field for all incoming keys
    READ ENTITIES OF zi_po IN LOCAL MODE
      ENTITY po
        FIELDS ( currency )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_pos)
      FAILED DATA(lt_failed).

    LOOP AT lt_pos INTO DATA(ls_po).
      IF ls_po-currency IS INITIAL.
        APPEND VALUE #( %tky = ls_po-%tky ) TO failed-po.
        APPEND VALUE #(
          %tky            = ls_po-%tky
          %element-currency = if_abap_behv=>mk-on
          %msg            = new_message_with_text(
                              severity = if_abap_behv_message=>severity-error
                              text     = 'Currency must not be empty' )
        ) TO reported-po.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_po_item IMPLEMENTATION.

  METHOD update_item.
    DATA: ls_item TYPE zpo_itm.

    LOOP AT entities INTO DATA(ls_entity).
      " Check if item exists and is not soft-deleted
      SELECT SINGLE @abap_true INTO DATA(lv_exists)
        FROM zpo_itm
        WHERE mandt      = @sy-mandt
          AND po_id      = @ls_entity-po_id
          AND item_no    = @ls_entity-item_no
          AND is_deleted = ' '.

      IF lv_exists IS NOT TRUE.
        APPEND VALUE #(
          %cid = ls_entity-%cid
          %msg = new_message( id = 'ZPO' number = '006'
                              v1 = ls_entity-item_no )
        ) TO reported-po_item.
        APPEND VALUE #( %cid = ls_entity-%cid ) TO failed-po_item.
        CONTINUE.
      ENDIF.

      " Prepare for update
      ls_item            = CORRESPONDING #( ls_entity ).
      ls_item-mandt      = sy-mandt.
      ls_item-changed_by = sy-uname.
      ls_item-changed_at = utclong_now( ).

      " Add to update buffer via controlled accessor
      lcl_buffer=>add_update_item( ls_item ).

      " Set mapped
      APPEND VALUE #(
        %cid    = ls_entity-%cid
        po_id   = ls_entity-po_id
        item_no = ls_entity-item_no
      ) TO mapped-po_item.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_item.
    DATA: ls_delete TYPE zpo_itm.

    LOOP AT entities INTO DATA(ls_entity).
      " Prepare for logical delete
      ls_delete-mandt   = sy-mandt.
      ls_delete-po_id   = ls_entity-po_id.
      ls_delete-item_no = ls_entity-item_no.

      " Add to delete buffer via controlled accessor
      lcl_buffer=>add_delete_item( ls_delete ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read_item.
    DATA: lt_result TYPE TABLE OF zi_po_item.

    " Read from CDS view (which already filters IS_DELETED = ' ')
    SELECT po_id, item_no, material, quantity, uom, net_price,
           currency, plant, created_by, created_at, changed_by, changed_at
      FROM zi_po_item
      FOR ALL ENTRIES IN @keys
      WHERE po_id   = @keys-po_id
        AND item_no = @keys-item_no
      INTO CORRESPONDING FIELDS OF TABLE @lt_result.

    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_idx) = sy-tabix.
      READ TABLE lt_result INTO DATA(ls_data)
        WITH KEY po_id   = ls_key-po_id
                 item_no = ls_key-item_no.
      IF sy-subrc = 0.
        APPEND CORRESPONDING #( ls_data ) TO result INDEX lv_idx.
      ELSE.
        APPEND INITIAL LINE TO result INDEX lv_idx.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_quantity.
    READ ENTITIES OF zi_po IN LOCAL MODE
      ENTITY po_item
        FIELDS ( quantity )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items)
      FAILED DATA(lt_failed).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-quantity <= 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-po_item.
        APPEND VALUE #(
          %tky              = ls_item-%tky
          %element-quantity = if_abap_behv=>mk-on
          %msg              = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Quantity must be greater than 0' )
        ) TO reported-po_item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validate_net_price.
    READ ENTITIES OF zi_po IN LOCAL MODE
      ENTITY po_item
        FIELDS ( net_price )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items)
      FAILED DATA(lt_failed).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-net_price < 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-po_item.
        APPEND VALUE #(
          %tky                = ls_item-%tky
          %element-net_price  = if_abap_behv=>mk-on
          %msg                = new_message_with_text(
                                  severity = if_abap_behv_message=>severity-error
                                  text     = 'Net Price must not be negative' )
        ) TO reported-po_item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_po IMPLEMENTATION.

  METHOD save_modified.
    DATA(lt_create_po)   = lcl_buffer=>get_create_po( ).
    DATA(lt_update_po)   = lcl_buffer=>get_update_po( ).
    DATA(lt_delete_po)   = lcl_buffer=>get_delete_po( ).
    DATA(lt_create_item) = lcl_buffer=>get_create_item( ).
    DATA(lt_update_item) = lcl_buffer=>get_update_item( ).
    DATA(lt_delete_item) = lcl_buffer=>get_delete_item( ).

    " ── PO Header: CREATE ────────────────────────────────────────────────────
    IF lt_create_po IS NOT INITIAL.
      INSERT zpo_hdr FROM TABLE @lt_create_po.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_no_check.
      ENDIF.
    ENDIF.

    " ── PO Item: CREATE ──────────────────────────────────────────────────────
    IF lt_create_item IS NOT INITIAL.
      INSERT zpo_itm FROM TABLE @lt_create_item.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_no_check.
      ENDIF.
    ENDIF.

    " ── PO Header: UPDATE ────────────────────────────────────────────────────
    IF lt_update_po IS NOT INITIAL.
      LOOP AT lt_update_po INTO DATA(ls_po_upd).
        UPDATE zpo_hdr SET
          vendor_id  = @ls_po_upd-vendor_id,
          doc_date   = @ls_po_upd-doc_date,
          currency   = @ls_po_upd-currency,
          status     = @ls_po_upd-status,
          changed_by = @ls_po_upd-changed_by,
          changed_at = @ls_po_upd-changed_at
          WHERE mandt = @sy-mandt
            AND po_id = @ls_po_upd-po_id.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_no_check.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " ── PO Item: UPDATE ──────────────────────────────────────────────────────
    IF lt_update_item IS NOT INITIAL.
      LOOP AT lt_update_item INTO DATA(ls_itm_upd).
        UPDATE zpo_itm SET
          material   = @ls_itm_upd-material,
          quantity   = @ls_itm_upd-quantity,
          uom        = @ls_itm_upd-uom,
          net_price  = @ls_itm_upd-net_price,
          currency   = @ls_itm_upd-currency,
          plant      = @ls_itm_upd-plant,
          changed_by = @ls_itm_upd-changed_by,
          changed_at = @ls_itm_upd-changed_at
          WHERE mandt   = @sy-mandt
            AND po_id   = @ls_itm_upd-po_id
            AND item_no = @ls_itm_upd-item_no.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_no_check.
        ENDIF.
      ENDLOOP.
    ENDIF.

    " ── PO Header: logical DELETE (cascade to items) ─────────────────────────
    IF lt_delete_po IS NOT INITIAL.
      LOOP AT lt_delete_po INTO DATA(ls_po_del).
        UPDATE zpo_hdr SET is_deleted = @abap_true
          WHERE mandt = @sy-mandt
            AND po_id = @ls_po_del-po_id.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_no_check.
        ENDIF.

        " Cascade: logically delete all items belonging to this PO
        UPDATE zpo_itm SET is_deleted = @abap_true
          WHERE mandt = @sy-mandt
            AND po_id = @ls_po_del-po_id.
      ENDLOOP.
    ENDIF.

    " ── PO Item: logical DELETE ───────────────────────────────────────────────
    IF lt_delete_item IS NOT INITIAL.
      LOOP AT lt_delete_item INTO DATA(ls_itm_del).
        UPDATE zpo_itm SET is_deleted = @abap_true
          WHERE mandt   = @sy-mandt
            AND po_id   = @ls_itm_del-po_id
            AND item_no = @ls_itm_del-item_no.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_no_check.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD finalize.
    lcl_buffer=>clear_all( ).
  ENDMETHOD.

ENDCLASS.