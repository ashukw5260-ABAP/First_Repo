"! Transaction buffer for PO operations.
"! Buffer data is PRIVATE; use the provided class methods to add/read entries.
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES:
      "! Sorted table type for PO header buffer entries
      tt_po_hdr  TYPE SORTED TABLE OF zpo_hdr WITH UNIQUE KEY mandt po_id,
      "! Sorted table type for PO item buffer entries
      tt_po_itm  TYPE SORTED TABLE OF zpo_itm WITH UNIQUE KEY mandt po_id item_no.

    CLASS-METHODS:
      "! Add a PO header record to the CREATE buffer
      add_create_po   IMPORTING is_po   TYPE zpo_hdr,
      "! Add a PO header record to the UPDATE buffer
      add_update_po   IMPORTING is_po   TYPE zpo_hdr,
      "! Add a PO header record to the DELETE buffer
      add_delete_po   IMPORTING is_po   TYPE zpo_hdr,
      "! Add a PO item record to the CREATE buffer
      add_create_item IMPORTING is_item TYPE zpo_itm,
      "! Add a PO item record to the UPDATE buffer
      add_update_item IMPORTING is_item TYPE zpo_itm,
      "! Add a PO item record to the DELETE buffer
      add_delete_item IMPORTING is_item TYPE zpo_itm,
      "! Return all PO header CREATE entries
      get_create_po   RETURNING VALUE(rt_result) TYPE tt_po_hdr,
      "! Return all PO header UPDATE entries
      get_update_po   RETURNING VALUE(rt_result) TYPE tt_po_hdr,
      "! Return all PO header DELETE entries
      get_delete_po   RETURNING VALUE(rt_result) TYPE tt_po_hdr,
      "! Return all PO item CREATE entries
      get_create_item RETURNING VALUE(rt_result) TYPE tt_po_itm,
      "! Return all PO item UPDATE entries
      get_update_item RETURNING VALUE(rt_result) TYPE tt_po_itm,
      "! Return all PO item DELETE entries
      get_delete_item RETURNING VALUE(rt_result) TYPE tt_po_itm,
      "! Clear all buffer tables (called by saver finalize)
      clear_all.

  PRIVATE SECTION.
    CLASS-DATA:
      mt_create_po   TYPE tt_po_hdr,
      mt_update_po   TYPE tt_po_hdr,
      mt_delete_po   TYPE tt_po_hdr,
      mt_create_item TYPE tt_po_itm,
      mt_update_item TYPE tt_po_itm,
      mt_delete_item TYPE tt_po_itm.
ENDCLASS.

"! Root entity handler for PO
CLASS lhc_po DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      create_po FOR MODIFY
        IMPORTING entities FOR CREATE zi_po,
      update_po FOR MODIFY
        IMPORTING entities FOR UPDATE zi_po,
      delete_po FOR MODIFY
        IMPORTING entities FOR DELETE zi_po,
      read_po FOR READ
        IMPORTING keys FOR READ zi_po
        RESULT result,
      create_items FOR MODIFY
        IMPORTING entities FOR CREATE zi_po\_Items,
      rba_items FOR READ
        IMPORTING keys_for_tabname FOR READ zi_po\_Items
        FULL result_failed,
      lock_po FOR LOCK
        IMPORTING keys FOR LOCK zi_po,
      global_authorization FOR AUTHORIZATION
        IMPORTING request FOR GLOBAL AUTHORIZATION zi_po
        RESULT result,
      "! Validate that VENDOR_ID is not empty
      validate_vendor_id FOR VALIDATE ON SAVE
        IMPORTING keys FOR zi_po~ValidateVendorId,
      "! Validate that CURRENCY is not empty
      validate_currency FOR VALIDATE ON SAVE
        IMPORTING keys FOR zi_po~ValidateCurrency.
ENDCLASS.

"! Child entity handler for PO Item
CLASS lhc_po_item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      update_item FOR MODIFY
        IMPORTING entities FOR UPDATE zi_po_item,
      delete_item FOR MODIFY
        IMPORTING entities FOR DELETE zi_po_item,
      read_item FOR READ
        IMPORTING keys FOR READ zi_po_item
        RESULT result,
      "! Validate that QUANTITY > 0
      validate_quantity FOR VALIDATE ON SAVE
        IMPORTING keys FOR zi_po_item~ValidateQuantity,
      "! Validate that NET_PRICE >= 0
      validate_net_price FOR VALIDATE ON SAVE
        IMPORTING keys FOR zi_po_item~ValidateNetPrice.
ENDCLASS.

"! Saver class for PO operations
CLASS lsc_po DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PRIVATE SECTION.
    METHODS:
      save_modified REDEFINITION,
      finalize REDEFINITION.
ENDCLASS.