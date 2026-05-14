@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Header Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_PO
  as select from zpo_hdr
  composition [0..*] of ZI_PO_ITEM as _Items
{
  key po_id      as PO_ID,
      vendor_id  as VENDOR_ID,
      doc_date   as DOC_DATE,
      currency   as CURRENCY,
      status     as STATUS,
      created_by as CREATED_BY,
      created_at as CREATED_AT,
      changed_by as CHANGED_BY,
      changed_at as CHANGED_AT,
      _Items
}
where
  is_deleted = ' '