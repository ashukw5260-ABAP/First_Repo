CLASS ztcl_po_rap_test DEFINITION
  PUBLIC
  FINAL
  FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    " ── Happy-path tests ─────────────────────────────────────────────────────
    METHODS:
      test_create          FOR TESTING,   " Create PO with 2 items
      test_read            FOR TESTING,   " Read items via association
      test_update_item     FOR TESTING,   " Update item quantity
      test_delete_item     FOR TESTING,   " Logical delete single item
      test_delete_po       FOR TESTING,   " Logical delete PO (cascade)

    " ── Validation / negative-path tests ─────────────────────────────────────
      test_create_missing_vendor   FOR TESTING,  " VENDOR_ID empty → fail
      test_create_missing_currency FOR TESTING,  " CURRENCY empty → fail
      test_create_duplicate_po_id  FOR TESTING,  " duplicate PO_ID → fail
      test_item_zero_quantity      FOR TESTING,  " QUANTITY = 0 → fail
      test_item_negative_price     FOR TESTING,  " NET_PRICE < 0 → fail
      test_item_missing_item_no    FOR TESTING,  " ITEM_NO empty → fail
      test_update_nonexistent_po   FOR TESTING,  " update deleted/absent PO → fail
      test_item_on_nonexistent_po  FOR TESTING.  " create item under missing PO → fail
ENDCLASS.

CLASS ztcl_po_rap_test IMPLEMENTATION.

  " ═══════════════════════════════════════════════════════════════════════════
  " HAPPY-PATH TESTS
  " ═══════════════════════════════════════════════════════════════════════════

  METHOD test_create.
    " Test: Create PO with 2 items – expect no failures
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id doc_date currency status )
        WITH VALUE #( (
          %cid      = 'PO1'
          po_id     = 'PO0000001'
          vendor_id = 'VENDOR01'
          doc_date  = sy-datum
          currency  = 'USD'
          status    = 'O'
        ) )
      ENTITY po
        CREATE BY \_items
          FIELDS ( item_no material quantity uom net_price currency plant )
          WITH VALUE #( (
            %cid_ref = 'PO1'
            %target = VALUE #(
              (
                %cid      = 'ITEM1'
                item_no   = '00010'
                material  = 'MAT001'
                quantity  = '5.000'
                uom       = 'EA'
                net_price = '10.00'
                currency  = 'USD'
                plant     = '1000'
              )
              (
                %cid      = 'ITEM2'
                item_no   = '00020'
                material  = 'MAT002'
                quantity  = '3.000'
                uom       = 'EA'
                net_price = '20.00'
                currency  = 'USD'
                plant     = '1000'
              )
            )
          ) )
      REPORTED DATA(ls_create_reported)
      FAILED   DATA(ls_create_failed)
      MAPPED   DATA(ls_create_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_initial(
      act = ls_create_failed
      msg = 'test_create: Create PO should not fail' ).
  ENDMETHOD.

  METHOD test_read.
    " Test: Read items of PO0000001 – expect 2 items returned
    READ ENTITIES OF zi_po
      ENTITY po
        BY \_items
          FIELDS ( po_id item_no material quantity )
          WITH VALUE #( ( po_id = 'PO0000001' ) )
      RESULT DATA(lt_items).

    cl_abap_unit_assert=>assert_equals(
      exp = 2
      act = lines( lt_items )
      msg = 'test_read: Expected 2 items for PO0000001' ).
  ENDMETHOD.

  METHOD test_update_item.
    " Test: Update item 00010 quantity to 10 – expect success and verified read
    MODIFY ENTITIES OF zi_po
      ENTITY po_item
        UPDATE FIELDS ( quantity )
        WITH VALUE #( (
          po_id    = 'PO0000001'
          item_no  = '00010'
          quantity = '10.000'
        ) )
      REPORTED DATA(ls_upd_reported)
      FAILED   DATA(ls_upd_failed).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_initial(
      act = ls_upd_failed
      msg = 'test_update_item: Update should not fail' ).

    READ ENTITIES OF zi_po
      ENTITY po_item
        FIELDS ( quantity )
        WITH VALUE #( ( po_id = 'PO0000001'  item_no = '00010' ) )
      RESULT DATA(lt_read).

    IF lt_read IS NOT INITIAL.
      cl_abap_unit_assert=>assert_equals(
        exp = '10.000'
        act = lt_read[ 1 ]-quantity
        msg = 'test_update_item: Quantity should be 10.000' ).
    ENDIF.
  ENDMETHOD.

  METHOD test_delete_item.
    " Test: Logical-delete item 00020 – expect 1 item remaining
    MODIFY ENTITIES OF zi_po
      ENTITY po_item
        DELETE WITH VALUE #( ( po_id = 'PO0000001'  item_no = '00020' ) )
      REPORTED DATA(ls_del_reported)
      FAILED   DATA(ls_del_failed).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_initial(
      act = ls_del_failed
      msg = 'test_delete_item: Delete should not fail' ).

    READ ENTITIES OF zi_po
      ENTITY po
        BY \_items
          FIELDS ( item_no )
          WITH VALUE #( ( po_id = 'PO0000001' ) )
      RESULT DATA(lt_remaining).

    cl_abap_unit_assert=>assert_equals(
      exp = 1
      act = lines( lt_remaining )
      msg = 'test_delete_item: Only 1 item should remain after delete' ).
  ENDMETHOD.

  METHOD test_delete_po.
    " Test: Logical-delete PO0000001 – PO should not appear in subsequent read
    MODIFY ENTITIES OF zi_po
      ENTITY po
        DELETE WITH VALUE #( ( po_id = 'PO0000001' ) )
      REPORTED DATA(ls_po_del_reported)
      FAILED   DATA(ls_po_del_failed).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_initial(
      act = ls_po_del_failed
      msg = 'test_delete_po: Delete PO should not fail' ).

    READ ENTITIES OF zi_po
      ENTITY po
        FIELDS ( po_id )
        WITH VALUE #( ( po_id = 'PO0000001' ) )
      RESULT DATA(lt_po).

    cl_abap_unit_assert=>assert_initial(
      act = lt_po
      msg = 'test_delete_po: Deleted PO should not appear in result' ).
  ENDMETHOD.

  " ═══════════════════════════════════════════════════════════════════════════
  " VALIDATION / NEGATIVE-PATH TESTS
  " ═══════════════════════════════════════════════════════════════════════════

  METHOD test_create_missing_vendor.
    " Test: Create PO without VENDOR_ID – expect validation failure
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_NO_VENDOR'
          po_id     = 'PO9990001'
          vendor_id = ''           " deliberately empty
          currency  = 'EUR'
          status    = 'O'
        ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_create_missing_vendor: Should fail when VENDOR_ID is empty' ).
  ENDMETHOD.

  METHOD test_create_missing_currency.
    " Test: Create PO without CURRENCY – expect validation failure
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_NO_CURR'
          po_id     = 'PO9990002'
          vendor_id = 'VENDOR01'
          currency  = ''           " deliberately empty
          status    = 'O'
        ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_create_missing_currency: Should fail when CURRENCY is empty' ).
  ENDMETHOD.

  METHOD test_create_duplicate_po_id.
    " Precondition: create PO9990010 once
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_DUP_1'
          po_id     = 'PO9990010'
          vendor_id = 'VENDOR01'
          currency  = 'USD'
          status    = 'O'
        ) )
      REPORTED DATA(ls_r1) FAILED DATA(ls_f1) MAPPED DATA(ls_m1).
    COMMIT ENTITIES.

    " Second create with the same PO ID – must fail
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_DUP_2'
          po_id     = 'PO9990010'   " duplicate key
          vendor_id = 'VENDOR02'
          currency  = 'EUR'
          status    = 'O'
        ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_create_duplicate_po_id: Duplicate PO ID must be rejected' ).

    " Clean-up: delete the first PO so it does not affect other tests
    MODIFY ENTITIES OF zi_po
      ENTITY po DELETE WITH VALUE #( ( po_id = 'PO9990010' ) )
      REPORTED DATA(ls_dc) FAILED DATA(ls_df).
    COMMIT ENTITIES.
  ENDMETHOD.

  METHOD test_item_zero_quantity.
    " Precondition: create a PO for this test
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_QTY'
          po_id     = 'PO9990020'
          vendor_id = 'VENDOR01'
          currency  = 'USD'
          status    = 'O'
        ) )
      ENTITY po
        CREATE BY \_items
          FIELDS ( item_no material quantity uom net_price currency )
          WITH VALUE #( (
            %cid_ref = 'PO_QTY'
            %target  = VALUE #( (
              %cid      = 'ITEM_ZERO'
              item_no   = '00010'
              material  = 'MAT001'
              quantity  = '0.000'   " zero quantity – must fail
              uom       = 'EA'
              net_price = '10.00'
              currency  = 'USD'
            ) )
          ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_item_zero_quantity: Quantity = 0 must be rejected' ).

    " Clean-up
    MODIFY ENTITIES OF zi_po
      ENTITY po DELETE WITH VALUE #( ( po_id = 'PO9990020' ) )
      REPORTED DATA(ls_dc) FAILED DATA(ls_df).
    COMMIT ENTITIES.
  ENDMETHOD.

  METHOD test_item_negative_price.
    " Precondition: create a PO for this test
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_PRICE'
          po_id     = 'PO9990030'
          vendor_id = 'VENDOR01'
          currency  = 'USD'
          status    = 'O'
        ) )
      ENTITY po
        CREATE BY \_items
          FIELDS ( item_no material quantity uom net_price currency )
          WITH VALUE #( (
            %cid_ref = 'PO_PRICE'
            %target  = VALUE #( (
              %cid      = 'ITEM_NEG'
              item_no   = '00010'
              material  = 'MAT001'
              quantity  = '1.000'
              uom       = 'EA'
              net_price = '-5.00'   " negative price – must fail
              currency  = 'USD'
            ) )
          ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_item_negative_price: Negative NET_PRICE must be rejected' ).

    " Clean-up
    MODIFY ENTITIES OF zi_po
      ENTITY po DELETE WITH VALUE #( ( po_id = 'PO9990030' ) )
      REPORTED DATA(ls_dc) FAILED DATA(ls_df).
    COMMIT ENTITIES.
  ENDMETHOD.

  METHOD test_item_missing_item_no.
    " Precondition: create a PO for this test
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE FIELDS ( po_id vendor_id currency status )
        WITH VALUE #( (
          %cid      = 'PO_ITEMNO'
          po_id     = 'PO9990040'
          vendor_id = 'VENDOR01'
          currency  = 'USD'
          status    = 'O'
        ) )
      ENTITY po
        CREATE BY \_items
          FIELDS ( item_no material quantity uom net_price currency )
          WITH VALUE #( (
            %cid_ref = 'PO_ITEMNO'
            %target  = VALUE #( (
              %cid      = 'ITEM_NONUM'
              item_no   = ''         " missing item number – must fail
              material  = 'MAT001'
              quantity  = '1.000'
              uom       = 'EA'
              net_price = '10.00'
              currency  = 'USD'
            ) )
          ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_item_missing_item_no: Empty ITEM_NO must be rejected' ).

    " Clean-up
    MODIFY ENTITIES OF zi_po
      ENTITY po DELETE WITH VALUE #( ( po_id = 'PO9990040' ) )
      REPORTED DATA(ls_dc) FAILED DATA(ls_df).
    COMMIT ENTITIES.
  ENDMETHOD.

  METHOD test_update_nonexistent_po.
    " Test: Update a PO that does not exist (or was deleted) – expect failure
    MODIFY ENTITIES OF zi_po
      ENTITY po
        UPDATE FIELDS ( status )
        WITH VALUE #( (
          po_id  = 'PO_GHOST_99'   " does not exist
          status = 'C'
        ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_update_nonexistent_po: Updating non-existent PO must fail' ).
  ENDMETHOD.

  METHOD test_item_on_nonexistent_po.
    " Test: Add item to a PO that does not exist – expect failure
    MODIFY ENTITIES OF zi_po
      ENTITY po
        CREATE BY \_items
          FIELDS ( item_no material quantity uom net_price currency )
          WITH VALUE #( (
            %cid_ref = 'PO_GHOST'
            %target  = VALUE #( (
              %cid      = 'ITEM_ORPHAN'
              item_no   = '00010'
              material  = 'MAT001'
              quantity  = '1.000'
              uom       = 'EA'
              net_price = '5.00'
              currency  = 'USD'
            ) )
          ) )
      REPORTED DATA(ls_reported)
      FAILED   DATA(ls_failed)
      MAPPED   DATA(ls_mapped).

    COMMIT ENTITIES.

    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed
      msg = 'test_item_on_nonexistent_po: Item under missing PO must fail' ).
  ENDMETHOD.

ENDCLASS.